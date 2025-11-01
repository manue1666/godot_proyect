extends Panel
class_name StatsPanel

var unit_name_label: Label
var unit_hp_label: Label
var unit_power_label: Label
var unit_movement_label: Label
var unit_status_label: Label

func _ready():
	_setup_references()

func _setup_references():
	unit_name_label = get_node("MarginContainer/VBoxContainer/NameLabel")
	unit_hp_label = get_node("MarginContainer/VBoxContainer/HBoxContainer/HPLabel")
	unit_power_label = get_node("MarginContainer/VBoxContainer/HBoxContainer/PowerLabel")
	unit_movement_label = get_node("MarginContainer/VBoxContainer/HBoxContainer/MovLabel")
	unit_status_label = get_node("MarginContainer/VBoxContainer/HBoxContainer/StatusLabel")

func update_stats(unit: BaseUnit):
	if not unit:
		return
	
	# Nombre con color
	var color = Color.WHITE if unit.team_id == 0 else Color.RED
	var team_label = "ALLY" if unit.team_id == 0 else "ENEMY"
	unit_name_label.text = "%s (%s)" % [unit.name.to_upper(), team_label]
	unit_name_label.add_theme_color_override("font_color", color)
	
	# HP
	if unit.health_component:
		var hp = unit.health_component.hp
		var max_hp = unit.health_component.max_hp
		unit_hp_label.text = "HP: %d/%d" % [hp, max_hp]
	
	# Power
	unit_power_label.text = "Power: %d" % unit.power
	
	# Movement
	if unit.movement_component:
		unit_movement_label.text = "Movement: %d" % unit.movement_component.current_range
	
	# Status
	_update_status(unit)

func _update_status(unit: BaseUnit):
	if unit.status_manager and unit.status_manager.has_active_effect():
		var effect_name = AttackData.Effect.keys()[unit.status_manager.current_effect]
		var turns_left = unit.status_manager.get_remaining_turns()
		unit_status_label.text = "⚠️ %s (%d turns)" % [effect_name, turns_left]
		unit_status_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		unit_status_label.text = "Normal"
		unit_status_label.add_theme_color_override("font_color", Color.GREEN)

func update_attacks(unit: BaseUnit):
	if not unit or not unit.attack_component:
		return
	
	var attack_one = unit.attack_component.get_attack(0)
	if attack_one:
		_update_attack_row(1, attack_one, unit)
	
	var attack_two = unit.attack_component.get_attack(1)
	if attack_two:
		_update_attack_row(2, attack_two, unit)

func _update_attack_row(attack_num: int, attack: AttackData, unit: BaseUnit):
	var attack_name_label: Label
	var damage_label: Label
	var range_label: Label
	var effect_label: Label
	
	if attack_num == 1:
		attack_name_label = get_node("MarginContainer/VBoxContainer/HBoxContainer2/AttackOneName")
		damage_label = get_node("MarginContainer/VBoxContainer/HBoxContainer2/DamageLabel")
		range_label = get_node("MarginContainer/VBoxContainer/HBoxContainer2/RangeLabel")
		effect_label = get_node("MarginContainer/VBoxContainer/HBoxContainer2/EffectLabel")
	else:
		attack_name_label = get_node("MarginContainer/VBoxContainer/HBoxContainer3/AttackTwoName")
		damage_label = get_node("MarginContainer/VBoxContainer/HBoxContainer3/DamageLabel")
		range_label = get_node("MarginContainer/VBoxContainer/HBoxContainer3/RangeLabel")
		effect_label = get_node("MarginContainer/VBoxContainer/HBoxContainer3/EffectLabel")
	
	attack_name_label.text = attack.attack_name
	damage_label.text = "Dm:%d" % (attack.damage + unit.power)
	
	var range_type_name = AttackData.RangeType.keys()[attack.range_type]
	var attack_type_name = AttackData.AttackType.keys()[attack.attack_type]
	range_label.text = "%s/%s(%d)" % [attack_type_name, range_type_name, attack.range]
	
	if attack.effect == AttackData.Effect.NONE:
		effect_label.text = "None(0)"
	else:
		var effect_name = AttackData.Effect.keys()[attack.effect]
		effect_label.text = "%s(%d)" % [effect_name, attack.effect_duration]
