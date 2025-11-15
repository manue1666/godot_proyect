extends Control
class_name LevelResultScreen

enum ResultType { VICTORY, DEFEAT, RUN_COMPLETE }

@onready var title_label: Label = $CenterContainer/Panel/VBoxContainer/TitleLabel
@onready var stats_label: Label = $CenterContainer/Panel/VBoxContainer/StatsLabel
@onready var continue_button: Button = $CenterContainer/Panel/VBoxContainer/HBoxContainer/ContinueButton
@onready var menu_button: Button = $CenterContainer/Panel/VBoxContainer/HBoxContainer/MenuButton

signal continue_pressed()
signal menu_pressed()

func _ready():
	add_to_group("level_result_screen")
	
	continue_button.pressed.connect(_on_continue_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	
	print("✅ LevelResultScreen inicializado")

func show_result(result_type: ResultType, current_level: int, total_levels: int, units_alive: int, total_units: int):
	match result_type:
		ResultType.VICTORY:
			title_label.text = "LEVEL COMPLETE!"
			title_label.modulate = Color.GREEN
			continue_button.text = "Next Level"
			continue_button.visible = true
		ResultType.DEFEAT:
			title_label.text = "DEFEAT"
			title_label.modulate = Color.RED
			continue_button.visible = false
		ResultType.RUN_COMPLETE:
			title_label.text = "RUN COMPLETE!!!"
			title_label.modulate = Color.GOLD
			continue_button.text = "Play Again"
			continue_button.visible = true
	
	stats_label.text = "Level: %d/%d\nUnits Alive: %d/%d" % [current_level, total_levels, units_alive, total_units]
	
	visible = true
	print("📊 Resultado mostrado: %s" % ResultType.keys()[result_type])

func hide_screen():
	visible = false

func _on_continue_pressed():
	continue_pressed.emit()
	hide_screen()

func _on_menu_pressed():
	menu_pressed.emit()
	hide_screen()
