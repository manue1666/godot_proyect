extends Area2D
class_name BaseUnit

signal clicked()
signal moved(unit: BaseUnit, new_position: Vector2i)
signal attacked(attacker: BaseUnit, target: BaseUnit, attack_num: int)
signal died(unit: BaseUnit)
signal receive_dam(damage: int, attacker: BaseUnit)

var tile_size := 32
var highlight_scene: PackedScene = preload("res://scenes/interfaz/move_sign.tscn")
var atack_highlight_scene: PackedScene = preload("res://scenes/interfaz/atack_sign.tscn")
var atack_range_highlight_scene: PackedScene = preload("res://scenes/interfaz/atack_range_sign.tscn")

@export var board_position := Vector2i(0, 0)
@export var power: int = 1

var highlights := []
var team: Team = null
var team_id: int = -1

# ✅ COMPONENTES - Referencias
var state_machine: UnitStateMachine
var movement_component: MovementComponent
var attack_component: AttackComponent
var animation_component: AnimationComponent
var health_component: HealthComponent
var status_manager: StatusManager

func _ready():
	add_to_group("units")
	
	# OBTENER COMPONENTES
	state_machine = get_node_or_null("UnitStateMachine")
	if not state_machine:
		push_error("❌ BaseUnit: No encontró UnitStateMachine como hijo")
		return
	
	movement_component = get_node_or_null("MovementComponent")
	attack_component = get_node_or_null("AttackComponent")
	animation_component = get_node_or_null("AnimationComponent")
	health_component = get_node_or_null("HealthComponent")
	status_manager = get_node_or_null("StatusManager")
	
	#Conectar señales de componentes
	if state_machine:
		state_machine.state_changed.connect(_on_state_changed)
	
	if health_component:
		health_component.died.connect(func(unit): died.emit(unit))
		health_component.damage_taken.connect(func(dmg, attacker): receive_dam.emit(dmg, attacker))
	
	if status_manager:
		# StatusManager ya conecta con TurnManager en su _ready()
		pass
	
	update_visual_position()
	connect("input_event", Callable(self, "_on_input_event"))
	
	$MenuPanel.visible = false
	$MenuPanel/Move.connect("pressed", Callable(self, "_on_boton_move_pressed"))
	$MenuPanel/Atack1.connect("pressed", Callable(self, "_on_boton_atack_one_pressed"))
	$MenuPanel/Atack2.connect("pressed", Callable(self, "_on_boton_atack_two_pressed"))

func _on_state_changed(old_state, new_state):
	print("[%s] Estado: %s → %s" % [
		name,
		UnitStateMachine.State.keys()[old_state],
		UnitStateMachine.State.keys()[new_state]
	])
	match new_state:
		UnitStateMachine.State.SELECTED:
			$MenuPanel.visible = true
		UnitStateMachine.State.IDLE, UnitStateMachine.State.EXHAUSTED:
			$MenuPanel.visible = false
			clear_highlights()
			if animation_component:
				animation_component.play_idle()
		UnitStateMachine.State.WAITING_MOVE:
			show_movable_tiles()
		UnitStateMachine.State.WAITING_ATTACK:
			pass
		UnitStateMachine.State.MOVING:
			if animation_component:
				animation_component.play_move()
		UnitStateMachine.State.ATTACKING:
			pass

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("🖱️ Click detectado en: %s" % name)
		clicked.emit()

func select_unit():
	if state_machine.can_act():
		state_machine.change_state(UnitStateMachine.State.SELECTED)

func deselect_unit():
	if not state_machine.is_exhausted():
		state_machine.change_state(UnitStateMachine.State.IDLE)
	clear_highlights()

func _unhandled_input(event):
	if not event is InputEventMouseButton or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	
	var click_pos = get_global_mouse_position()
	var cell_clicked = Vector2i(
		int(click_pos.x / tile_size),
		int(click_pos.y / tile_size)
	)
	
	if state_machine.is_waiting_move():
		if movement_component:
			var did_move = await movement_component.move_to(cell_clicked)
			if did_move:
				state_machine.use_move_action()
				moved.emit(self, cell_clicked)
				clear_highlights()
				state_machine.change_state(UnitStateMachine.State.IDLE)
	
	elif state_machine.is_waiting_attack():
		var target = get_unit_at_cell(cell_clicked)
		if target and attack_component:
			if attack_component.perform_attack(target, state_machine.attack_number - 1):
				state_machine.use_attack_action()
				attacked.emit(self, target, state_machine.attack_number)
				await play_attack_animation(state_machine.attack_number)
				clear_highlights()
				state_machine.change_state(UnitStateMachine.State.IDLE)

func play_attack_animation(attack_num: int):
	if not animation_component:
		return
	
	if attack_num == 1:
		await animation_component.play_attack_one()
	elif attack_num == 2:
		await animation_component.play_attack_two()
	
	if animation_component.is_playing:
		await animation_component.animation_finished

# Delegado a HealthComponent
func receive_damage(damage: int, attacker: BaseUnit):
	if health_component:
		health_component.take_damage(damage, attacker)
	spawn_damage_popup(damage)

func update_visual_position():
	position = Vector2(board_position.x, board_position.y) * tile_size + Vector2(tile_size * 0.5, tile_size * 0.5)

func show_movable_tiles():
	clear_highlights()
	if not movement_component:
		return
	
	var cells = movement_component.get_movable_cells()
	for cell in cells:
		var h = highlight_scene.instantiate()
		h.position = Vector2(cell.x, cell.y) * tile_size + Vector2(tile_size * 0.5, tile_size * 0.5)
		get_parent().add_child(h)
		highlights.append(h)

func show_atack_tiles(atack_num: int):
	clear_highlights()
	if not attack_component:
		return
	
	var cells = attack_component.get_attackable_cells(atack_num - 1)
	for cell in cells:
		var target = get_unit_at_cell(cell)
		var h
		if target and attack_component.can_attack_target(target, atack_num - 1):
			h = atack_highlight_scene.instantiate()
		else:
			h = atack_range_highlight_scene.instantiate()
		h.position = Vector2(cell.x, cell.y) * tile_size + Vector2(tile_size * 0.5, tile_size * 0.5)
		get_parent().add_child(h)
		highlights.append(h)

func clear_highlights():
	for h in highlights:
		h.queue_free()
	highlights.clear()

func spawn_damage_popup(damage: int):
	var popup = preload("res://scenes/interfaz/damage_popup.tscn").instantiate()
	popup.damage_amount = damage
	popup.position = position + Vector2(0, -tile_size * 0.5)
	get_parent().add_child(popup)

func get_unit_at_cell(cell: Vector2i) -> BaseUnit:
	var units = get_tree().get_nodes_in_group("units")
	for unit in units:
		if unit is BaseUnit and unit.board_position == cell:
			return unit
	return null


func _on_boton_move_pressed():
	if not state_machine.can_move():
		print("❌ No hay acciones de movimiento disponibles")
		return
	
	$MenuPanel.visible = false
	state_machine.change_state(UnitStateMachine.State.WAITING_MOVE)

func _on_boton_atack_one_pressed():
	if not state_machine.can_attack():
		print("❌ No hay acciones de ataque disponibles")
		return
	
	$MenuPanel.visible = false
	state_machine.attack_number = 1
	state_machine.change_state(UnitStateMachine.State.WAITING_ATTACK)
	show_atack_tiles(1)

func _on_boton_atack_two_pressed():
	if not state_machine.can_attack():
		print("❌ No hay acciones de ataque disponibles")
		return
	
	$MenuPanel.visible = false
	state_machine.attack_number = 2
	state_machine.change_state(UnitStateMachine.State.WAITING_ATTACK)
	show_atack_tiles(2)
