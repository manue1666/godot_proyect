extends Node

class_name TurnManager

var selected_unit: Area2D = null

func _ready():
	add_to_group("turn_manager")

func unit_clicked(unit):
	# Deselecciona la unidad anterior si existe
	if selected_unit and selected_unit != unit:
		selected_unit.deselect_unit()

	# Selecciona la nueva unidad si no estaba seleccionada
	if selected_unit != unit:
		selected_unit = unit
		unit.select_unit()
	else:
		# Si se hace click en la misma unidad, se deselecciona
		unit.deselect_unit()
		selected_unit = null
