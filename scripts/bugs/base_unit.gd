extends Area2D
class_name BaseUnit

signal clicked()
signal moved(unit: BaseUnit, new_position: Vector2i)
signal attacked(attacker: BaseUnit, target: BaseUnit, attack_num: int)
signal died(unit: BaseUnit)

var tile_size := 32
@export var highlight_scene: PackedScene = preload("res://scenes/interfaz/move_sign.tscn")
@export var atack_highlight_scene: PackedScene = preload("res://scenes/interfaz/atack_sign.tscn")

@export var board_position := Vector2i(0, 0)
var highlights := []
var team: Team = null
var team_id: int = -1

# State machine
var state_machine: UnitStateMachine

# STATS BASE DE UNIDAD
@export var max_hp: int = 10
@export var hp: int = 10
@export var move_range := 1
@export var power: int = 1

# ATAQUES DE UNIDAD
@export var atack_one := {"name": "Atack 1", "damage": 5, "range": 1, "type": "physical", "effect": "none"}
@export var atack_two := {"name": "Atack 2", "damage": 5, "range": 2, "type": "ranged", "effect": "none"}

func _ready():

	add_to_group("units")
	# Crear state machine
	state_machine = UnitStateMachine.new()
	add_child(state_machine)
	state_machine.state_changed.connect(_on_state_changed)
	
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
		UnitStateMachine.State.WAITING_MOVE:
			show_movable_tiles()
		UnitStateMachine.State.WAITING_ATTACK:
			# Ya se muestran los tiles en el botón
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
	
	# Manejar movimiento
	if state_machine.is_waiting_move():
		var valid_cells = get_movable_cells()
		if cell_clicked in valid_cells and is_cell_free(cell_clicked):
			move_to(cell_clicked)
			state_machine.change_state(UnitStateMachine.State.EXHAUSTED)
			moved.emit(self, cell_clicked)
	
	# Manejar ataque
	elif state_machine.is_waiting_attack():
		var target = get_unit_at_cell(cell_clicked)
		if target and can_attack_target(target, state_machine.attack_number):
			attack_target(target, state_machine.attack_number)
			state_machine.change_state(UnitStateMachine.State.EXHAUSTED)
			attacked.emit(self, target, state_machine.attack_number)

func move_to(new_board_pos: Vector2i):
	board_position = new_board_pos
	update_visual_position()
	clear_highlights()

func attack_target(target: BaseUnit, atack_num: int):
	var atack = atack_one if atack_num == 1 else atack_two
	target.receive_damage(atack["damage"] + power, self)
	clear_highlights()
	# RECOMENDACIÓN: Aquí podrías agregar animación de ataque

func receive_damage(damage: int, attacker: BaseUnit):
	hp -= damage
	print("%s recibió %d de daño de %s. HP: %d/%d" % [name, damage, attacker.name, hp, max_hp])
	
	# RECOMENDACIÓN: Aquí podrías agregar:
	# - Animación de daño
	# - Números flotantes mostrando el daño
	# - Efecto de pantalla shake
	
	if hp <= 0:
		die()

func die():
	state_machine.change_state(UnitStateMachine.State.DEAD)
	died.emit(self)
	# RECOMENDACIÓN: Agregar animación de muerte antes de queue_free
	queue_free()

func update_visual_position():
	position = Vector2(board_position.x, board_position.y) * tile_size + Vector2(tile_size * 0.5, tile_size * 0.5)

func get_movable_cells() -> Array:
	var cells := []
	for x in range(-move_range, move_range + 1):
		for y in range(-move_range, move_range + 1):
			var distance = abs(x) + abs(y)  # Distancia Manhattan
			if distance > 0 and distance <= move_range:  # Excluye la casilla actual
				var cell = board_position + Vector2i(x, y)
				if is_cell_valid(cell) and is_cell_free(cell):
					cells.append(cell)
	return cells

func get_attackable_cells(atack_num: int) -> Array:
	var atack = atack_one if atack_num == 1 else atack_two
	var cells := []
	for x in range(-atack["range"], atack["range"] + 1):
		for y in range(-atack["range"], atack["range"] + 1):
			var distance = abs(x) + abs(y)
			if distance > 0 and distance <= atack["range"]:  # Excluye la casilla actual
				var cell = board_position + Vector2i(x, y)
				if is_cell_valid(cell):
					cells.append(cell)
	return cells

func show_movable_tiles():
	clear_highlights()
	var cells = get_movable_cells()
	for cell in cells:
		var h = highlight_scene.instantiate()
		h.position = Vector2(cell.x, cell.y) * tile_size + Vector2(tile_size * 0.5, tile_size * 0.5)
		get_parent().add_child(h)
		highlights.append(h)

func show_atack_tiles(atack_num: int):
	clear_highlights()
	var cells = get_attackable_cells(atack_num)
	for cell in cells:
		# Solo mostrar si hay un enemigo atacable en esa posición
		var target = get_unit_at_cell(cell)
		if target and can_attack_target(target, atack_num):
			var h = atack_highlight_scene.instantiate()
			h.position = Vector2(cell.x, cell.y) * tile_size + Vector2(tile_size * 0.5, tile_size * 0.5)
			get_parent().add_child(h)
			highlights.append(h)

func clear_highlights():
	for h in highlights:
		h.queue_free()
	highlights.clear()

# Validaciones
func is_cell_valid(cell: Vector2i) -> bool:
	# RECOMENDACIÓN: Aquí deberías validar contra los límites del tablero
	# Por ahora asumimos que el tablero es 32x32
	return cell.x >= 0 and cell.x < 32 and cell.y >= 0 and cell.y < 32

func is_cell_free(cell: Vector2i) -> bool:
	var units = get_tree().get_nodes_in_group("units")
	for unit in units:
		if unit is BaseUnit and unit.board_position == cell and unit != self:
			return false
	return true

func get_unit_at_cell(cell: Vector2i) -> BaseUnit:
	var units = get_tree().get_nodes_in_group("units")
	for unit in units:
		if unit is BaseUnit and unit.board_position == cell:
			return unit
	return null

func can_attack_target(target: BaseUnit, atack_num: int) -> bool:
	if not target or target == self:
		return false
	if not team or not target.team:
		return false
	if not team.is_enemy(target.team):
		return false
	if target.state_machine.is_dead():
		return false
	
	var cells = get_attackable_cells(atack_num)
	return target.board_position in cells

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

# Métodos para acceder/modificar hijos comunes
func set_sprite_texture(texture: Texture2D):
	if has_node("Sprite2D"):
		$Sprite2D.texture = texture

func set_collision_shape(shape: Shape2D):
	if has_node("CollisionShape2D"):
		$CollisionShape2D.shape = shape
