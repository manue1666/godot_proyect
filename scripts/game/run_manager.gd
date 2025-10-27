extends Node
class_name RunManager

signal level_completed(level_num: int)
signal run_completed()
signal run_failed()

@export var total_levels: int = 5
var current_level: int = 0
var levels_completed: int = 0

# Referencias
var map_generator: MapGenerator
var turn_manager: TurnManager
var battle_hud: BattleHUD
var result_screen: LevelResultScreen
var currency_manager: CurrencyManager
var reward_calculator: RewardCalculator
var shop_inventory: ShopInventory
var shop_screen: ShopScreen
var team_stats_tracker: TeamStatsTracker
var enemy_spawner: EnemySpawner

func _ready():
	add_to_group("run_manager")
	
	await get_tree().process_frame
	
	# Buscar referencias
	map_generator = get_tree().get_first_node_in_group("map_generator")
	turn_manager = get_tree().get_first_node_in_group("turn_manager")
	currency_manager = get_tree().get_first_node_in_group("currency_manager")
	reward_calculator = get_tree().get_first_node_in_group("reward_calculator")
	shop_inventory = get_tree().get_first_node_in_group("shop_inventory")
	shop_screen = get_tree().get_first_node_in_group("shop_screen")
	team_stats_tracker = get_tree().get_first_node_in_group("team_stats_tracker")
	enemy_spawner = get_tree().get_first_node_in_group("enemy_spawner")
	
	# Si UI es hermano de RunManager
	var ui_node = get_parent().get_node_or_null("UI")
	if ui_node:
		battle_hud = ui_node.get_node_or_null("BattleHUD")
		result_screen = ui_node.get_node_or_null("LevelResultScreen")
	
	# Debug
	print("🔍 RunManager inicializando...")
	print("  MapGenerator: %s" % ("✅" if map_generator else "❌"))
	print("  TurnManager: %s" % ("✅" if turn_manager else "❌"))
	print("  BattleHUD: %s" % ("✅" if battle_hud else "❌"))
	print("  ResultScreen: %s" % ("✅" if result_screen else "❌"))
	print("  CurrencyManager: %s" % ("✅" if currency_manager else "❌"))
	print("  RewardCalculator: %s" % ("✅" if reward_calculator else "❌"))
	print("  ShopInventory: %s" % ("✅" if shop_inventory else "❌"))
	print("  ShopScreen: %s" % ("✅" if shop_screen else "❌"))
	print("  TeamStatsTracker: %s" % ("✅" if team_stats_tracker else "❌"))
	print("  EnemySpawner: %s" % ("✅" if enemy_spawner else "❌"))

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
	
	if shop_screen:
		shop_screen.shop_closed.connect(_on_shop_closed)
	
	start_new_run()

func _on_map_generated(_map_data: MapData):
	print("📍 RunManager recibió mapa generado")

func start_new_run():
	current_level = 0
	levels_completed = 0
	
	if currency_manager:
		currency_manager.reset_coins()
	
	if shop_inventory:
		shop_inventory.clear_inventory()
	
	# LIMPIAR STATS
	if team_stats_tracker:
		team_stats_tracker.clear()
	
	print("\n🎮 === NUEVA RUN INICIADA ===")
	start_next_level()

func start_next_level():
	current_level += 1
	
	if current_level > total_levels:
		_show_run_complete()
		return
	
	print("\n📍 === NIVEL %d/%d ===" % [current_level, total_levels])
	
	# ✅ GENERAR ENEMIGOS PARA ESTE NIVEL
	if enemy_spawner:
		enemy_spawner.spawn_enemies_for_level(current_level)
	else:
		push_error("❌ EnemySpawner no encontrado!")
	
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
		
		# Procesar recompensa
		if reward_calculator:
			reward_calculator.process_victory_reward(current_level)
		
		# GENERAR TIENDA
		if shop_inventory:
			shop_inventory.generate_items(current_level)
		
		_show_level_complete(winner_team)
	else:
		_show_defeat()

func _show_level_complete(winner_team: Team):
	print("🎉 Nivel completado!")
	
	# ✅ MOSTRAR TIENDA
	if shop_screen:
		print("🛍️ Mostrando tienda...")
		shop_screen.show_shop()
	elif not result_screen:
		print("  ⚠️  No hay ResultScreen, auto-continuando...")
		await get_tree().create_timer(2.0).timeout
		start_next_level()
		return
	else:
		var units_alive = winner_team.get_living_units().size()
		var total_units = winner_team.units.size()
		
		result_screen.show_result(
			LevelResultScreen.ResultType.VICTORY,
			current_level,
			total_levels,
			units_alive,
			total_units
		)

# Manejador para cuando se cierra la tienda
func _on_shop_closed():
	print("🛍️ Tienda cerrada, continuando...")
	
	# ✅ ESPERAR UN FRAME para asegurar que las unidades estén listas
	await get_tree().process_frame
	
	if team_stats_tracker and turn_manager and turn_manager.teams.size() > 0:
		var player_team = turn_manager.teams[0]
		team_stats_tracker.apply_all_boosts_to_team(player_team)

	if battle_hud:
		battle_hud.update_boosts_display()
	
	start_next_level()

func _show_defeat():
	print("💀 Derrota - Run terminada")
	
	# RESETEAR monedas al perder
	if currency_manager:
		print("🔄 Reseteando monedas por derrota")
		currency_manager.reset_coins()
	
	# LIMPIAR INVENTARIO AL PERDER
	if shop_inventory:
		shop_inventory.clear_inventory()
	
	# LIMPIAR STATS AL PERDER
	if team_stats_tracker:
		team_stats_tracker.clear()
	
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
	
	# Mostrar monedas finales
	if currency_manager:
		currency_manager.print_status()
	
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
