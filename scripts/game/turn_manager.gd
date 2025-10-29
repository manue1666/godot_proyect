extends Node
class_name TurnManager

signal turn_started(team: Team)
signal turn_ended(team: Team)
signal battle_ended(winner_team: Team)
signal unit_selected(unit: BaseUnit)

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
			if unit and is_instance_valid(unit):
				print("    · Conectando señales de: %s" % unit.name)
				
				# CONECTAR TODAS LAS SEÑALES
				unit.clicked.connect(_on_unit_clicked.bind(unit))
				unit.moved.connect(_on_unit_moved)       
				unit.attacked.connect(_on_unit_attacked)    
				unit.died.connect(_on_unit_died)
				unit.receive_dam.connect(_on_unit_received_damage)

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

# HANDLERS DE SEÑALES 

func _on_unit_clicked(unit: BaseUnit):
	print("🖱️ Unidad clickeada: %s" % unit.name)
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
		unit_selected.emit(unit)
	else:
		unit.deselect_unit()
		selected_unit = null
		print("✅ Unidad deseleccionada")

func _on_unit_moved(unit: BaseUnit, new_position: Vector2i):
	print("📍 %s se movió a %v" % [unit.name, new_position])
	unit.board_position = new_position
	unit.update_visual_position()
	check_turn_end()

func _on_unit_attacked(attacker: BaseUnit, target: BaseUnit, attack_num: int):
	print("⚔️ %s atacó a %s con ataque %d" % [attacker.name, target.name, attack_num])
	check_turn_end()

func _on_unit_died(unit: BaseUnit):
	print("💀 %s murió" % unit.name)
	if unit == selected_unit:
		selected_unit = null
	# Verificar batalla
	check_battle_end()

func _on_unit_received_damage(damage: int, attacker: BaseUnit):
	print("🏥 %s recibió %d de daño" % [attacker.name, damage])

func get_current_team() -> Team:
	return teams[current_team_index] if current_team_index < teams.size() else null

func start_turn():
	var current_team = teams[current_team_index]
	print("\n=== Turno de %s ===" % current_team.team_name)
	
	# Resetear SOLO si es el equipo del jugador
	if current_team.team_id == 0:
		for unit in current_team.get_living_units():
			if unit.state_machine:
				# Resetear acciones
				unit.state_machine.reset_actions()
				
				if unit.state_machine.is_exhausted():
					unit.state_machine.change_state(UnitStateMachine.State.IDLE)
		print("  ✅ Estados y acciones reseteados (equipo del jugador)")
	
	await get_tree().process_frame
	turn_started.emit(current_team)

func check_turn_end():
	var current_team = get_current_team()
	# Solo verificar si quedan unidades del jugador que actúen
	if current_team.team_id == 0:
		if not current_team.has_units_that_can_act():
			print("  📋 Equipo %s completó su turno" % current_team.team_name)

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
	
	print("  🔍 Equipos vivos: %d" % alive_teams.size())
	
	if alive_teams.size() <= 1:
		var winner = alive_teams[0] if alive_teams.size() == 1 else null
		battle_ended.emit(winner)
		
		if winner:
			print("\n🎉 ¡%s GANÓ LA BATALLA! 🎉" % winner.team_name)
		else:
			print("\n💀 ¡EMPATE! Todos murieron 💀")

func connect_unit_signals(unit: BaseUnit):
	if not unit or not is_instance_valid(unit):
		push_warning("⚠️  Intentando conectar señales a unidad inválida")
		return
	
	print("    🔗 Conectando señales a: %s" % unit.name)
	
	# Desconectar si ya estaban conectadas (evitar duplicados)
	if unit.clicked.is_connected(_on_unit_clicked):
		unit.clicked.disconnect(_on_unit_clicked)
	if unit.moved.is_connected(_on_unit_moved):
		unit.moved.disconnect(_on_unit_moved)
	if unit.attacked.is_connected(_on_unit_attacked):
		unit.attacked.disconnect(_on_unit_attacked)
	if unit.died.is_connected(_on_unit_died):
		unit.died.disconnect(_on_unit_died)
	if unit.receive_dam.is_connected(_on_unit_received_damage):
		unit.receive_dam.disconnect(_on_unit_received_damage)
	
	# Conectar nuevas señales
	unit.clicked.connect(_on_unit_clicked.bindv([unit]))
	unit.moved.connect(_on_unit_moved)
	unit.attacked.connect(_on_unit_attacked)
	unit.died.connect(_on_unit_died)
	unit.receive_dam.connect(_on_unit_received_damage)
	
	print("    ✅ Señales conectadas correctamente")

func reset_all_units_for_new_battle():
	print("\n🔄 === RESETEANDO UNIDADES PARA NUEVA BATALLA ===")
	
	var team_stats_tracker = get_tree().get_first_node_in_group("team_stats_tracker")
	
	for team in teams:
		for unit in team.get_living_units():
			if not is_instance_valid(unit):
				continue
			
			print("  🔄 Reseteando: %s" % unit.name)
			
			# RESETEAR MOVIMIENTO CON BOOSTS
			if unit.has_node("MovementComponent"):
				var movement_comp = unit.get_node("MovementComponent") as MovementComponent
				
				if team_stats_tracker:
					movement_comp.set_range_boost(team_stats_tracker.get_movement_boost())
					print("    · Movement: %d (base %d + boost %d)" % [
						movement_comp.current_range,
						movement_comp.original_range,
						team_stats_tracker.get_movement_boost()
					])
				else:
					movement_comp.reset_range()

			# RESETEAR PODER CON BOOSTS
			if team_stats_tracker:
				unit.power = 0 + team_stats_tracker.get_power_boost()
				print("    · Power: %d (base 0 + boost %d)" % [unit.power, team_stats_tracker.get_power_boost()])
			else:
				unit.power = 0
			
			# RESETEAR ESTADO
			if unit.state_machine:
				unit.state_machine.change_state(UnitStateMachine.State.IDLE)
				unit.state_machine.reset_for_new_turn()
				unit.state_machine.reset_actions()
			
			# CONSERVAR HP
			if unit.has_node("HealthComponent"):
				var health_comp = unit.get_node("HealthComponent") as HealthComponent
				print("    · HP conservado: %d/%d" % [health_comp.hp, health_comp.max_hp])
				
				if health_comp.hp <= 0:
					unit.state_machine.change_state(UnitStateMachine.State.DEAD)
					print("    · Unidad muerta (HP = 0)")
			
			# LIMPIAR EFECTOS
			if unit.has_node("StatusManager"):
				var status_manager = unit.get_node("StatusManager") as StatusManager
				status_manager.clear_all_effects()
				print("    · Efectos de estado limpiados")
			
			# DESELECCIONAR
			if unit == selected_unit:
				selected_unit = null
			
			unit.deselect_unit()
	
	print("✅ Todas las unidades reseteadas\n")
