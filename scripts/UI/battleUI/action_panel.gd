extends Panel
class_name ActionPanel

var move_button: Button
var attack_one_button: Button
var attack_two_button: Button

signal move_pressed()
signal attack_one_pressed()
signal attack_two_pressed()

func _ready():
	_setup_buttons()

func _setup_buttons():
	move_button = get_node("Move")
	attack_one_button = get_node("Attack_one")
	attack_two_button = get_node("Attack_two")
	
	if move_button:
		move_button.pressed.connect(_on_move_pressed)
	if attack_one_button:
		attack_one_button.pressed.connect(_on_attack_one_pressed)
	if attack_two_button:
		attack_two_button.pressed.connect(_on_attack_two_pressed)

func update_attack_buttons(unit: BaseUnit):
	if not unit or not unit.attack_component:
		return
	
	var attack_one = unit.attack_component.get_attack(0)
	if attack_one and attack_one_button:
		attack_one_button.text = attack_one.attack_name
	
	var attack_two = unit.attack_component.get_attack(1)
	if attack_two and attack_two_button:
		attack_two_button.text = attack_two.attack_name

func _on_move_pressed():
	move_pressed.emit()

func _on_attack_one_pressed():
	attack_one_pressed.emit()

func _on_attack_two_pressed():
	attack_two_pressed.emit()
