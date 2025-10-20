extends Node
class_name RunManager

signal level_completed(level_num: int)
signal run_completed()
signal run_failed()

@export var total_levels: int = 15
var current_level: int = 0
var levels_completed: int = 0

var map_generator: MapGenerator
var turn_manager: TurnManager
var battle_hud: BattleHUD
var result_screen: LevelResultScreen

func _ready():
	add_to_group("run_manager")
	
	# Esperar un frame para que todos los nodos estén listos
	await get_tree().process_frame
	
	# Buscar referencias
	map_generator = get_tree().get_first_node_in_group("map_generator")
	turn_manager = get_tree().get_first_node_in_group("turn_manager")
	
	# Si UI es hermano de RunManager
	var ui_node = get_parent().get_node_or_null("UI")
	if ui_node:
		battle_hud = ui_node.get_node_or_null("BattleHUD")
		result_screen = ui_node.get_node_or_null("LevelResultScreen")
	
	# Debug: Verificar que encontró todo
	print("🔍 RunManager inicializando...")
	print("  MapGenerator: %s" % ("✅" if map_generator else "❌"))
	print("  TurnManager: %s" % ("✅" if turn_manager else "❌"))
	print("  BattleHUD: %s" % ("✅" if battle_hud else "❌"))
	print("  ResultScreen: %s" % ("✅" if result_screen else "❌"))
	
	# Conectar señales
	if map_generator:
		map_generator.map_generated.connect(_on_map_generated)
	
	if turn_manager:
		turn_manager.battle_ended.connect(_on_battle_ended)
		if turn_manager.has_signal("turn_started"):
			turn_manager.turn_started.connect(_on_turn_started)
	
	if battle_hud:
		if battle_hud.has_signal("end_turn_pressed"):
			battle_hud.end_turn_pressed.connect(_on_end_turn_button_pressed)
	
	if result_screen:
		result_screen.continue_pressed.connect(_on_result_continue)
		result_screen.menu_pressed.connect(_on_result_menu)
	
	# Iniciar run
	start_new_run()

func _on_map_generated(_map_data: MapData):
	print("📍 RunManager recibió mapa generado")

func start_new_run():
	current_level = 0
	levels_completed = 0
	print("\n🎮 === NUEVA RUN INICIADA ===")
	start_next_level()

func start_next_level():
	current_level += 1
	
	if current_level > total_levels:
		_show_run_complete()
		return
	
	print("\n📍 === NIVEL %d/%d ===" % [current_level, total_levels])
	
	# Actualizar HUD
	if battle_hud:
		battle_hud.update_level(current_level, total_levels)
		print("  ✅ BattleHUD actualizado")
	else:
		print("  ⚠️  BattleHUD no encontrado")
	
	# Generar mapa
	if map_generator:
		map_generator.obstacle_density = 0.1 + (current_level * 0.005)
		map_generator.generate_new_map()
	else:
		push_error("❌ MapGenerator no encontrado!")

func _on_battle_ended(winner_team: Team):
	print("\n🏁 Batalla terminada - Ganador: %s" % (winner_team.team_name if winner_team else "Empate"))
	
	if winner_team and winner_team.team_id == 0:  # Team del jugador ganó
		levels_completed += 1
		level_completed.emit(current_level)
		_show_level_complete(winner_team)
	else:
		_show_defeat()

func _show_level_complete(winner_team: Team):
	print("🎉 Nivel completado!")
	
	if not result_screen:
		print("  ⚠️  No hay ResultScreen, auto-continuando...")
		await get_tree().create_timer(2.0).timeout
		start_next_level()
		return
	
	var units_alive = winner_team.get_living_units().size()
	var total_units = winner_team.units.size()
	
	# Usar enum de LevelResultScreen
	result_screen.show_result(
		LevelResultScreen.ResultType.VICTORY,
		current_level,
		total_levels,
		units_alive,
		total_units
	)

func _show_defeat():
	print("💀 Derrota - Run terminada")
	
	if not result_screen:
		return
	
	var player_team = turn_manager.teams[0] if turn_manager and turn_manager.teams.size() > 0 else null
	var units_alive = player_team.get_living_units().size() if player_team else 0
	var total_units = player_team.units.size() if player_team else 0
	
	result_screen.show_result(
		LevelResultScreen.ResultType.DEFEAT,
		current_level,
		total_levels,
		units_alive,
		total_units
	)
	
	run_failed.emit()

func _show_run_complete():
	print("🎉 Run completada - 15/15 niveles!")
	
	if not result_screen:
		return
	
	var player_team = turn_manager.teams[0] if turn_manager and turn_manager.teams.size() > 0 else null
	var units_alive = player_team.get_living_units().size() if player_team else 0
	var total_units = player_team.units.size() if player_team else 0
	
	result_screen.show_result(
		LevelResultScreen.ResultType.RUN_COMPLETE,
		total_levels,
		total_levels,
		units_alive,
		total_units
	)
	
	run_completed.emit()

func _on_turn_started(team: Team):
	if battle_hud:
		battle_hud.update_turn(team.team_name)
		
		# Mostrar botón End Turn solo si es turno del jugador (team_id = 0)
		if team.team_id == 0:
			battle_hud.end_turn_button.visible = true
			print("🎮 Botón End Turn VISIBLE (turno del jugador)")
		else:
			battle_hud.end_turn_button.visible = false
			print("🤖 Botón End Turn OCULTO (turno de IA)")

func _on_end_turn_button_pressed():
	print("⏭️  Botón End Turn presionado")
	if turn_manager:
		turn_manager.end_turn()

func _on_result_continue():
	print("➡️  Continuando al siguiente nivel...")
	start_next_level()

func _on_result_menu():
	print("🏠 Volviendo al menú principal...")
	get_tree().change_scene_to_file("res://scenes/interfaz/UI/main_menu.tscn")

func _heal_team_between_levels():
	var player_team = turn_manager.teams[0] if turn_manager and turn_manager.teams.size() > 0 else null
	if player_team:
		for unit in player_team.get_living_units():
			var old_hp = unit.hp
			unit.hp = min(unit.hp + 3, unit.max_hp)
			print("  💚 %s: %d → %d HP" % [unit.name, old_hp, unit.hp])
