extends Node

class_name TurnManager

var selected_unit: Area2D = null
var equipos := []  # [ [unidad1, unidad2], [rival1, rival2] ]
var equipo_actual := 0
var unidades_restantes := []

func _ready():
	add_to_group("turn_manager")
	equipos = [[$"../blue_ant"], [$"../red_ant"]]
	iniciar_turno()

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

func iniciar_turno():
	unidades_restantes = equipos[equipo_actual].duplicate()
	for unidad in unidades_restantes:
		unidad.can_select = true
	print("comienza turno")

func unidad_actuo(unidad):
	unidad.can_select = false
	unidades_restantes.erase(unidad)
	if unidades_restantes.size() == 0:
		terminar_turno()

func terminar_turno():
	# Desactiva todas las unidades del equipo actual
	for unidad in equipos[equipo_actual]:
		unidad.can_select = false
		unidad.deselect_unit()
	# Cambia de equipo
	equipo_actual = (equipo_actual + 1) % equipos.size()
	print("termino el turno")
	iniciar_turno()

func check_battle_end():
	var vivos := []
	for equipo in equipos:
		for unidad in equipo:
			if is_instance_valid(unidad):
				vivos.append(unidad)
	if vivos.size() <= 1:
		print("¡Batalla terminada! Ganador: ", vivos[0].name if vivos.size() == 1 else "Nadie")
		get_tree().paused = true
