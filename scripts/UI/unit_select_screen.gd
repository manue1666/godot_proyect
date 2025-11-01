extends Control
class_name UnitSelectScreen

@onready var blue_ant_button: Button = $PanelContainer/HBoxContainer/BlueAnt
@onready var red_ant_button: Button = $PanelContainer/HBoxContainer/RedAnt
@onready var warrior_ant_button: Button = $PanelContainer/HBoxContainer/WarriorAnt
@onready var termite_button: Button = $PanelContainer/HBoxContainer/Termite
@onready var fly_button: Button = $PanelContainer/HBoxContainer/Fly

# Mapear botones a unit_ids del catálogo
var unit_buttons: Dictionary = {}

func _ready():
	print("🐜 === UNIT SELECT SCREEN ===\n")
	
	# Mapear botones a IDs del catálogo
	unit_buttons = {
		"blue_ant": blue_ant_button,
		"red_ant": red_ant_button,
		"warrior_ant": warrior_ant_button,
		"termite": termite_button,
		"fly": fly_button
	}
	
	# Conectar señales
	for unit_id in unit_buttons.keys():
		unit_buttons[unit_id].pressed.connect(_on_unit_selected.bindv([unit_id]))
		print("  ✅ Botón %s conectado" % unit_id)

func _on_unit_selected(unit_id: String):
	print("\n👾 Unidad seleccionada: %s" % unit_id)
	
	# Usar directamente el autoload GState
	GState.selected_unit_id = unit_id
	
	print("  📦 GState.selected_unit_id = %s" % unit_id)
	print("  🚀 Cargando Main...\n")
	
	# Cargar escena principal
	get_tree().change_scene_to_file("res://scenes/main.tscn")
