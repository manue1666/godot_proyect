extends Node
class_name TurnManager

signal turn_started(team: Team)
signal turn_ended(team: Team)
signal battle_ended(winner_team: Team)

@export var teams: Array[Team] = []
var current_team_index := 0
var selected_unit: BaseUnit = null
var map_generator: MapGenerator

func _ready():
	add_to_group("turn_manager")

	map_generator = get_tree().get_first_node_in_group("map_generator")
	if map_generator:
		map_generator.map_generated.connect(_on_map_generated)
	
	# Buscar equipos automáticamente si no están asignados
	if teams.is_empty():
		for child in get_parent().get_children():
			if child is Team:
				teams.append(child)
	
	print("📋 Equipos encontrados: %d" % teams.size())
	
	# ESPERAR un frame para que Team._ready() se ejecute primero
	await get_tree().process_frame
	
	# Conectar señales de todas las unidades
	for team in teams:
		print("  - Team: %s con %d unidades" % [team.team_name, team.units.size()])
		for unit in team.units:
			print("    · Conectando señales de: %s" % unit.name)
			unit.clicked.connect(_on_unit_clicked.bind(unit))
			unit.moved.connect(_on_unit_moved)
			unit.attacked.connect(_on_unit_attacked)
			unit.died.connect(_on_unit_died)
	
	start_turn()

func _on_map_generated(map_data: MapData):
	print("🗺️  TurnManager recibió mapa generado")
	
	# Esperar un frame para que las unidades estén listas
	await get_tree().process_frame
	
	# Posicionar equipos
	if teams.size() >= 2:
		_spawn_team(teams[0], map_data.spawn_positions_team1)
		_spawn_team(teams[1], map_data.spawn_positions_team2)

func _spawn_team(team: Team, spawn_positions: Array[Vector2i]):
	if spawn_positions.is_empty():
		push_warning("⚠️  No hay posiciones de spawn para %s" % team.team_name)
		return
	
	var units = team.get_living_units()
	print("  Posicionando %d unidades de %s" % [units.size(), team.team_name])
	
	for i in range(units.size()):
		if i < spawn_positions.size():
			units[i].board_position = spawn_positions[i]
		else:
			# Reutilizar posiciones si hay más unidades que slots
			var pos_index = i % spawn_positions.size()
			units[i].board_position = spawn_positions[pos_index]
		
		units[i].update_visual_position()
		print("    · %s → %s" % [units[i].name, units[i].board_position])

func _on_unit_clicked(unit: BaseUnit):
	print("📢 TurnManager recibió click de: %s" % unit.name)
	# Solo permitir seleccionar unidades del equipo actual
	if unit.team != get_current_team():
		print("❌ No es tu turno")
		return
	
	# Si la unidad ya actuó, no se puede seleccionar
	if unit.state_machine.is_exhausted() or unit.state_machine.is_dead():
		print("❌ Esta unidad ya actuó")
		return
	
	# Deseleccionar unidad anterior
	if selected_unit and selected_unit != unit:
		selected_unit.deselect_unit()
	
	# Seleccionar o deseleccionar
	if selected_unit != unit:
		selected_unit = unit
		unit.select_unit()
		print("✅ Unidad seleccionada: %s" % unit.name)
	else:
		unit.deselect_unit()
		selected_unit = null
		print("✅ Unidad deseleccionada")

func _on_unit_moved(unit: BaseUnit, _new_position: Vector2i):
	print("🚶 %s se movió" % unit.name)
	check_turn_end()

func _on_unit_attacked(attacker: BaseUnit, target: BaseUnit, attack_num: int):
	print("⚔️ %s atacó a %s con ataque %d" % [attacker.name, target.name, attack_num])
	check_turn_end()

func _on_unit_died(unit: BaseUnit):
	print("💀 %s murió" % unit.name)
	if unit == selected_unit:
		selected_unit = null
	check_battle_end()

func get_current_team() -> Team:
	return teams[current_team_index] if current_team_index < teams.size() else null

func start_turn():
	print("\n=== Turno de %s ===" % teams[current_team_index].team_name)
	
	turn_started.emit(teams[current_team_index])
	
	# Resetear estado de todas las unidades del equipo actual
	for unit in teams[current_team_index].get_living_units():
		if unit.state_machine:
			unit.state_machine.change_state(UnitStateMachine.State.IDLE)

func check_turn_end():
	var current_team = get_current_team()
	if not current_team.has_units_that_can_act():
		end_turn()

func end_turn():
	var current_team = get_current_team()
	turn_ended.emit(current_team)
	print("=== Fin del turno de %s ===" % current_team.team_name)
	
	# Deseleccionar cualquier unidad seleccionada
	if selected_unit:
		selected_unit.deselect_unit()
		selected_unit = null
	
	# Cambiar al siguiente equipo
	current_team_index = (current_team_index + 1) % teams.size()
	start_turn()

func check_battle_end():
	var alive_teams := []
	for team in teams:
		if team.get_living_units().size() > 0:
			alive_teams.append(team)
	
	if alive_teams.size() <= 1:
		var winner = alive_teams[0] if alive_teams.size() == 1 else null
		battle_ended.emit(winner)
		
		if winner:
			print("\n🎉 ¡%s GANÓ LA BATALLA! 🎉" % winner.team_name)
		else:
			print("\n💀 ¡EMPATE! Todos murieron 💀")
		
		# RECOMENDACIÓN: Aquí podrías mostrar una pantalla de victoria
		# Por ahora solo pausamos
		await get_tree().create_timer(2.0).timeout
