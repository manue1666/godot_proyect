extends Node

class_name Team

@export var team_id: int = 0
@export var team_name: String = "Team"
@export var team_color: Color = Color.WHITE

var units: Array[BaseUnit] = []

func _ready():
	# Si es el equipo del jugador (team_id = 0), esperar selección
	if team_id == 0:
		await get_tree().process_frame
		_setup_player_team()
	else:
		# Equipo enemigo: usar unidades hardcodeadas
		for child in get_children():
			if child is BaseUnit:
				add_unit(child)

func _setup_player_team():
	print("🎮 Configurando equipo del jugador...")
	
	var selected_unit_id = GState.selected_unit_id
	print("  📦 Unidad seleccionada: %s" % selected_unit_id)
	
	# Limpiar unidades actuales
	for child in get_children():
		if child is BaseUnit:
			child.queue_free()
	
	# Crear la unidad seleccionada
	var scene = UnitCatalog.get_scene(selected_unit_id)
	if scene:
		var new_unit = scene.instantiate() as BaseUnit
		add_child(new_unit)
		new_unit.board_position = Vector2i(3, 3)
		add_unit(new_unit)
		print("  ✅ %s añadida al equipo" % selected_unit_id)
	else:
		push_error("❌ No se pudo cargar escena para %s" % selected_unit_id)

func add_unit(unit: BaseUnit):
	if unit not in units:
		units.append(unit)
		unit.team = self
		unit.team_id = team_id

func remove_unit(unit: BaseUnit):
	units.erase(unit)

func get_living_units() -> Array[BaseUnit]:
	var living: Array[BaseUnit] = []
	for unit in units:
		if is_instance_valid(unit) and not unit.state_machine.is_dead():
			living.append(unit)
	return living

func has_units_that_can_act() -> bool:
	for unit in get_living_units():
		if unit.state_machine.can_act():
			return true
	return false

func reset_units_for_turn():
	for unit in get_living_units():
		unit.state_machine.reset_for_new_turn()

func is_enemy(other_team: Team) -> bool:
	return team_id != other_team.team_id
