extends Control
class_name BattleHUD

@onready var level_label: Label = $ButtomBar/MarginContainer/HBoxContainer/LevelLabel
@onready var turn_label: Label = $ButtomBar/MarginContainer/HBoxContainer/TurnLabel
@onready var end_turn_button: Button = $Turn

signal end_turn_pressed()

func _ready():
	end_turn_button.pressed.connect(_on_end_turn_pressed)

func update_level(current: int, total: int):
	level_label.text = "Level %d/%d" % [current, total]

func update_turn(team_name: String):
	turn_label.text = "Turn: %s" % team_name

func _on_end_turn_pressed():
	end_turn_pressed.emit()
