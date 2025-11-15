extends Control
class_name UnitSelectScreen

@onready var blue_ant_button: Button = $PanelContainer/HBoxContainer/BlueAnt
@onready var red_ant_button: Button = $PanelContainer/HBoxContainer/RedAnt
@onready var warrior_ant_button: Button = $PanelContainer/HBoxContainer/WarriorAnt
@onready var termite_button: Button = $PanelContainer/HBoxContainer/Termite
@onready var fly_button: Button = $PanelContainer/HBoxContainer/Fly

var unit_buttons: Dictionary = {}

func _ready():
	print("🐜 === UNIT SELECT SCREEN ===\n")
	
	# Verificar que RunManager existe
	if not run_manager:
		push_error("❌ RunManager no encontrado como Autoload")
		return
	
	print("✅ RunManager encontrado (ID: %d)" % run_manager.get_instance_id())
	
	unit_buttons = {
		"blue_ant": blue_ant_button,
		"red_ant": red_ant_button,
		"warrior_ant": warrior_ant_button,
		"termite": termite_button,
		"fly": fly_button
	}
	
	for unit_id in unit_buttons.keys():
		unit_buttons[unit_id].pressed.connect(_on_unit_selected.bind(unit_id))
		print("  ✅ Botón %s conectado" % unit_id)

func _on_unit_selected(unit_id: String):
	print("\n👾 Unidad seleccionada: %s" % unit_id)
	
	GState.selected_unit_id = unit_id
	
	print("  📦 GState.selected_unit_id = %s" % unit_id)
	print("  🚀 Iniciando nueva run...")
	print("  🆔 RunManager ID: %d\n" % run_manager.get_instance_id())
	
	# RunManager es global (Autoload), NO se instancia con .new()
	run_manager.start_new_run()
	
	print("  ✅ RunManager.start_new_run() llamado")
