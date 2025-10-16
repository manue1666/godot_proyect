extends Node
class_name TurnManager

signal turn_started(team: Team)
signal turn_ended(team: Team)
signal battle_ended(winner_team: Team)

@export var teams: Array[Team] = []
var current_team_index := 0
var selected_unit: BaseUnit = null

func _ready():
	add_to_group("turn_manager")
	
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
	var current_team = get_current_team()
	if not current_team:
		return
	
	current_team.reset_units_for_turn()
	turn_started.emit(current_team)
	print("\n=== Turno de %s ===" % current_team.team_name)

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
		get_tree().paused = true
