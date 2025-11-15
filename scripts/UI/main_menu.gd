extends Control
class_name MainMenu

@onready var new_run_button: Button = $CenterContainer/VBoxContainer/NewRunButton
@onready var settings_button: Button = $CenterContainer/VBoxContainer/SettingsButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton

func _ready():
	new_run_button.pressed.connect(_on_new_run_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	print("MainMenu inicializado")

func _on_new_run_pressed():
	print("🎮 Iniciando nueva run...")
	get_tree().change_scene_to_file("res://scenes/interfaz/UI/unit_select_screen.tscn")

func _on_settings_pressed():
	print("⚙️ Settings (no implementado aún)")

func _on_quit_pressed():
	print("👋 Saliendo del juego...")
	get_tree().quit()

func _on_play_button_pressed():
	print("🎮 Botón Play presionado")
	print("🆔 Llamando a RunManager (ID: %d)" % run_manager.get_instance_id())
	# El RunManager es global, no necesitas buscarlo
	run_manager.start_new_run()
