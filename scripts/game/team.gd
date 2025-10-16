extends Node

class_name Team

@export var team_id: int = 0
@export var team_name: String = "Team"
@export var team_color: Color = Color.WHITE

var units: Array[BaseUnit] = []

func _ready():
	# Encuentra todas las unidades hijas y las agrega al equipo
	for child in get_children():
		if child is BaseUnit:
			add_unit(child)

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
