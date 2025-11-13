extends Panel
class_name StatsPanel

# Referencias a Labels
var unit_name_label: Label
var unit_hp_label: Label
var unit_power_label: Label
var unit_movement_label: Label
var unit_status_label: Label

# Referencias a TextureRects para Status
var status_texture: TextureRect

# Referencias a Attack 1
var attack_one_name_label: Label
var attack_one_damage_label: Label
var attack_one_type_texture: TextureRect
var attack_one_range_texture: TextureRect
var attack_one_range_label: Label
var attack_one_effect_texture: TextureRect
var attack_one_effect_label: Label

# Referencias a Attack 2
var attack_two_name_label: Label
var attack_two_damage_label: Label
var attack_two_type_texture: TextureRect
var attack_two_range_texture: TextureRect
var attack_two_range_label: Label
var attack_two_effect_texture: TextureRect
var attack_two_effect_label: Label

func _ready():
	_setup_references()

func _setup_references():
	# Stats Panel
	unit_name_label = get_node("MarginContainer/VBoxContainer/NameLabel")
	unit_hp_label = get_node("MarginContainer/VBoxContainer/UnitStatsContainer/HPLabel")
	unit_power_label = get_node("MarginContainer/VBoxContainer/UnitStatsContainer/PowerLabel")
	unit_movement_label = get_node("MarginContainer/VBoxContainer/UnitStatsContainer/MovLabel")
	
	# Status
	status_texture = get_node_or_null("MarginContainer/VBoxContainer/UnitStatsContainer/StatusTexture")
	unit_status_label = get_node_or_null("MarginContainer/VBoxContainer/UnitStatsContainer/StatusLabel")
	
	# Attack 1
	attack_one_name_label = get_node("MarginContainer/VBoxContainer/AttackOneInfo/AttackOneName")
	attack_one_damage_label = get_node("MarginContainer/VBoxContainer/AttackOneInfo/DamageLabel")
	attack_one_type_texture = get_node_or_null("MarginContainer/VBoxContainer/AttackOneInfo/AttackTypeTexture")
	attack_one_range_texture = get_node_or_null("MarginContainer/VBoxContainer/AttackOneInfo/RangeTypeTexture")
	attack_one_range_label = get_node_or_null("MarginContainer/VBoxContainer/AttackOneInfo/RangeLabel")
	attack_one_effect_texture = get_node_or_null("MarginContainer/VBoxContainer/AttackOneInfo/EffectTexture")
	attack_one_effect_label = get_node_or_null("MarginContainer/VBoxContainer/AttackOneInfo/EffectLabel")
	
	# Attack 2
	attack_two_name_label = get_node("MarginContainer/VBoxContainer/AttackTwoInfo/AttackTwoName")
	attack_two_damage_label = get_node("MarginContainer/VBoxContainer/AttackTwoInfo/DamageLabel")
	attack_two_type_texture = get_node_or_null("MarginContainer/VBoxContainer/AttackTwoInfo/AttackTypeTexture")
	attack_two_range_texture = get_node_or_null("MarginContainer/VBoxContainer/AttackTwoInfo/RangeTypeTexture")
	attack_two_range_label = get_node_or_null("MarginContainer/VBoxContainer/AttackTwoInfo/RangeLabel")
	attack_two_effect_texture = get_node_or_null("MarginContainer/VBoxContainer/AttackTwoInfo/EffectTexture")
	attack_two_effect_label = get_node_or_null("MarginContainer/VBoxContainer/AttackTwoInfo/EffectLabel")

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
		unit_hp_label.text = "%d/%d" % [hp, max_hp]
	
	# Power
	unit_power_label.text = "%d" % unit.power
	
	# Movement - Usar la función pública get_current_range()
	if unit.movement_component:
		unit_movement_label.text = "%d" % unit.movement_component.get_current_range()
	
	# Status
	_update_status(unit)

func _update_status(unit: BaseUnit):
	if unit.status_manager and unit.status_manager.has_active_effect():
		var effect_enum = unit.status_manager.get_current_effect()
		var turns_left = unit.status_manager.get_remaining_turns()
		
		# Mostrar icono dinámico
		if status_texture:
			status_texture.visible = true
			# Mapear Effect enum a frame: POISON=0, STUN=1, SLOW=2
			var frame_index = _get_effect_frame(effect_enum)
			_set_texture_frame(status_texture, frame_index)
		
		# Mostrar solo el número de turnos
		if unit_status_label:
			unit_status_label.text = "%d" % turns_left
			unit_status_label.visible = true
	else:
		# Ocultar si no hay efecto
		if status_texture:
			status_texture.visible = false
		if unit_status_label:
			unit_status_label.visible = false

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
	var type_texture: TextureRect
	var range_texture: TextureRect
	var range_label: Label
	var effect_texture: TextureRect
	var effect_label: Label
	
	if attack_num == 1:
		attack_name_label = attack_one_name_label
		damage_label = attack_one_damage_label
		type_texture = attack_one_type_texture
		range_texture = attack_one_range_texture
		range_label = attack_one_range_label
		effect_texture = attack_one_effect_texture
		effect_label = attack_one_effect_label
	else:
		attack_name_label = attack_two_name_label
		damage_label = attack_two_damage_label
		type_texture = attack_two_type_texture
		range_texture = attack_two_range_texture
		range_label = attack_two_range_label
		effect_texture = attack_two_effect_texture
		effect_label = attack_two_effect_label
	
	# Nombre y Daño
	attack_name_label.text = attack.attack_name
	damage_label.text = "%d" % (attack.damage + unit.power)
	
	# Attack Type Icon (PHYSICAL=0, RANGED=1, AREA=2)
	if type_texture:
		type_texture.visible = true
		var attack_type_frame = _get_attack_type_frame(attack.attack_type)
		_set_texture_frame(type_texture, attack_type_frame)
	
	# Range Type Icon - Mapeo: SQUARE(0), X(1), CROSS(2), CIRCLE(3), LINE(4), KNIGHT(5), DIAMOND(7)
	if range_texture:
		range_texture.visible = true
		var range_type_frame = _get_range_type_frame(attack.range_type)
		_set_texture_frame(range_texture, range_type_frame)
	
	# Range Label (solo el número)
	if range_label:
		range_label.text = "%d" % attack.range
	
	# Effect Icon y Label
	if attack.effect == AttackData.Effect.NONE or attack.effect == AttackData.Effect.HEAL:
		# Ocultar si no hay efecto o es HEAL (no se muestra visualmente)
		if effect_texture:
			effect_texture.visible = false
		if effect_label:
			effect_label.visible = false
	else:
		# Mostrar icono dinámico (POISON=0, STUN=1, SLOW=2)
		if effect_texture:
			effect_texture.visible = true
			var effect_frame = _get_effect_frame(attack.effect)
			_set_texture_frame(effect_texture, effect_frame)
		
		# Mostrar solo la duración
		if effect_label:
			effect_label.text = "%d" % attack.effect_duration
			effect_label.visible = true


func _get_effect_frame(effect: AttackData.Effect) -> int:
	match effect:
		AttackData.Effect.POISON:
			return 0
		AttackData.Effect.SLOW:
			return 1
		AttackData.Effect.STUN:
			return 2
		_:
			return 0

# Mapear AttackType enum a frame index
# PHYSICAL=0, RANGED=1, AREA=2
func _get_attack_type_frame(attack_type: AttackData.AttackType) -> int:
	match attack_type:
		AttackData.AttackType.PHYSICAL:
			return 0
		AttackData.AttackType.RANGED:
			return 1
		AttackData.AttackType.AREA:
			return 2
		_:
			return 0

# Frames en spritesheet: SQUARE(0), X(1), CROSS(2), CIRCLE(3), LINE(4), KNIGHT(5), TELEPORT(6), DIAMOND(7)
func _get_range_type_frame(range_type: AttackData.RangeType) -> int:
	match range_type:
		AttackData.RangeType.SQUARE:
			return 0
		AttackData.RangeType.X:
			return 1
		AttackData.RangeType.CROSS:
			return 2
		AttackData.RangeType.LINE:
			return 4
		AttackData.RangeType.CIRCLE:
			return 3
		AttackData.RangeType.KNIGHT:
			return 5
		AttackData.RangeType.DIAMOND:
			return 7
		_:
			return 0

# Función auxiliar para cambiar el frame de AnimatedTexture
func _set_texture_frame(texture_rect: TextureRect, frame_index: int):
	if not texture_rect or not texture_rect.texture is AnimatedTexture:
		return
	
	var animated_tex = texture_rect.texture as AnimatedTexture
	var frame_count = animated_tex.frames
	
	# Validar que el frame index sea válido
	if frame_index < 0 or frame_index >= frame_count:
		push_warning("Frame index %d fuera de rango [0, %d) en %s" % [frame_index, frame_count, texture_rect.name])
		return
	
	animated_tex.current_frame = frame_index
