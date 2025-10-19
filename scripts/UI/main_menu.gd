extends Control
class_name MainMenu

@onready var new_run_button: Button = $CenterContainer/VBoxContainer/NewRunButton
@onready var settings_button: Button = $CenterContainer/VBoxContainer/SettingsButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton

func _ready():
	new_run_button.pressed.connect(_on_new_run_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_new_run_pressed():
	print("🎮 Iniciando nueva run...")
	# change_scene_to_file para cambiar completamente
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_settings_pressed():
	print("⚙️ Settings (no implementado aún)")

func _on_quit_pressed():
	print("👋 Saliendo del juego...")
	get_tree().quit()
