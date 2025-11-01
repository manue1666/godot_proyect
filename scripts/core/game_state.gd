extends Node
class_name GameState

var selected_unit_id: String = "blue_ant"

func _ready():
	add_to_group("game_state")
