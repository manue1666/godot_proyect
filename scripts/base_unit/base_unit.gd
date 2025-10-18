extends Area2D
class_name BaseUnit

signal clicked()
signal moved(unit: BaseUnit, new_position: Vector2i)
signal attacked(attacker: BaseUnit, target: BaseUnit, attack_num: int)
signal died(unit: BaseUnit)

var tile_size := 32
var highlight_scene: PackedScene = preload("res://scenes/interfaz/move_sign.tscn")
var atack_highlight_scene: PackedScene = preload("res://scenes/interfaz/atack_sign.tscn")
var atack_range_highlight_scene: PackedScene = preload("res://scenes/interfaz/atack_range_sign.tscn")

@export var board_position := Vector2i(0, 0)
var highlights := []
var team: Team = null
var team_id: int = -1

# Components
var state_machine: UnitStateMachine
var movement_component: MovementComponent
var attack_component: AttackComponent
var animation_component: AnimationComponent  # ← NUEVO

# STATS BASE
@export var max_hp: int = 10
@export var hp: int = 10
@export var power: int = 1

func _ready():
	add_to_group("units")
	
	# Inicializar componentes
	state_machine = UnitStateMachine.new()
	add_child(state_machine)
	state_machine.state_changed.connect(_on_state_changed)
	
	# Buscar componentes existentes
	movement_component = get_node_or_null("MovementComponent")
	attack_component = get_node_or_null("AttackComponent")
	animation_component = get_node_or_null("AnimationComponent")  # ← NUEVO
	
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
			# ← NUEVO: Reproducir idle
			if animation_component:
				animation_component.play_idle()
		UnitStateMachine.State.WAITING_MOVE:
			show_movable_tiles()
		UnitStateMachine.State.WAITING_ATTACK:
			pass
		UnitStateMachine.State.MOVING:  # ← NUEVO (si agregas estado MOVING)
			if animation_component:
				animation_component.play_move()
		UnitStateMachine.State.ATTACKING:  # ← NUEVO (si agregas estado ATTACKING)
			pass  # La animación se maneja en attack_target()

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
	
	# Manejar movimiento
	if state_machine.is_waiting_move():
		if movement_component:
			var did_move = await movement_component.move_to(cell_clicked)
			if did_move:
				state_machine.change_state(UnitStateMachine.State.EXHAUSTED)
				moved.emit(self, cell_clicked)
				clear_highlights()
	
	# Manejar ataque
	elif state_machine.is_waiting_attack():
		var target = get_unit_at_cell(cell_clicked)
		if target and attack_component:
			if attack_component.perform_attack(target, state_machine.attack_number - 1):
				# Reproducir animación de ataque
				attacked.emit(self, target, state_machine.attack_number)
				await play_attack_animation(state_machine.attack_number)
				state_machine.change_state(UnitStateMachine.State.EXHAUSTED)
				clear_highlights()

# Función para reproducir animación de ataque
func play_attack_animation(attack_num: int):
	if not animation_component:
		return
	
	if attack_num == 1:
		animation_component.play_attack_one()
	elif attack_num == 2:
		animation_component.play_attack_two()
	
	# Esperar a que termine la animación
	if animation_component.is_playing:
		await animation_component.animation_finished

func receive_damage(damage: int, attacker: BaseUnit):
	hp -= damage
	print("%s recibió %d de daño de %s. HP: %d/%d" % [name, damage, attacker.name, hp, max_hp])
	
	# flash y shake suave
	if has_node("AnimatedSprite2D"):
		var sprite = $AnimatedSprite2D
		var original_pos = sprite.position
		
		var damage_tween = create_tween()
		damage_tween.set_parallel(true)
		
		# Flash rojo
		damage_tween.tween_property(sprite, "modulate", Color.RED, 0.08)
		damage_tween.tween_property(sprite, "modulate", Color.WHITE, 0.08).set_delay(0.08)
		
		# Shake simple (solo 2 sacudidas)
		damage_tween.tween_property(sprite, "position", original_pos + Vector2(2, 0), 0.04)
		damage_tween.tween_property(sprite, "position", original_pos + Vector2(-2, 0), 0.04).set_delay(0.04)
		damage_tween.tween_property(sprite, "position", original_pos, 0.04).set_delay(0.08)
	
	spawn_damage_popup(damage)
	if hp <= 0:
		die()



func die():
	state_machine.change_state(UnitStateMachine.State.DEAD)
	
	# ← NUEVO: Reproducir animación de muerte
	if animation_component:
		animation_component.play_dead()
		# Esperar a que termine la animación antes de destruir
		var anim_duration = animation_component.get_animation_duration("dead")
		await get_tree().create_timer(anim_duration).timeout
	
	died.emit(self)
	queue_free()

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
	popup.position = position + Vector2(0, -tile_size * 0.5)  # Arriba del sprite
	get_parent().add_child(popup)

func get_unit_at_cell(cell: Vector2i) -> BaseUnit:
	var units = get_tree().get_nodes_in_group("units")
	for unit in units:
		if unit is BaseUnit and unit.board_position == cell:
			return unit
	return null

# Botones del menú
func _on_boton_move_pressed():
	$MenuPanel.visible = false
	state_machine.change_state(UnitStateMachine.State.WAITING_MOVE)

func _on_boton_atack_one_pressed():
	$MenuPanel.visible = false
	state_machine.attack_number = 1
	state_machine.change_state(UnitStateMachine.State.WAITING_ATTACK)
	show_atack_tiles(1)

func _on_boton_atack_two_pressed():
	$MenuPanel.visible = false
	state_machine.attack_number = 2
	state_machine.change_state(UnitStateMachine.State.WAITING_ATTACK)
	show_atack_tiles(2)
