extends Area2D
class_name BaseUnit

var tile_size := 32
@export var highlight_scene: PackedScene = preload("res://scenes/interfaz/move_sign.tscn")
@export var atack_highlight_scene: PackedScene = preload("res://scenes/interfaz/atack_sign.tscn")

@export var board_position := Vector2i(0,0)
var is_selected := false
var highlights := []
var can_select := true
var can_move := true

#STATS BASE DE UNIDAD
@export var hp: int = 10 # puntos de vida base
@export var move_range := 1 # rango de movimiento por casillas
@export var power:int = 1 # aumentador de daño general

#ATAQUES DE UNIDAD     =  nombre, daño, rango, tipo(physical/area/ranged), efecto(stun/heal/poison/none) 
@export var atack_one := {"name": "Atack 1", "damage": 5, "range": 1, "type": "physical", "effect": "none"}
@export var atack_two := {"name": "Atack 2", "damage": 5, "range": 2, "type": "ranged", "effect": "none"}



func _ready():
	update_visual_position()
	connect("input_event", Callable(self, "_on_input_event"))
	$MenuPanel.visible = false
	$MenuPanel/Move.connect("pressed", Callable(self, "_on_boton_move_pressed"))
	$MenuPanel/Atack1.connect("pressed", Callable(self, "_on_boton_atack_one_pressed"))
	$MenuPanel/Atack2.connect("pressed", Callable(self, "_on_boton_atack_two_pressed"))

func _on_input_event(_viewport, event, _shape_idx):
	print("hp: ", hp)
	if not can_select:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var managers = get_tree().get_nodes_in_group("turn_manager")
		if managers.size() > 0:
			managers[0].unit_clicked(self)
		else:
			if is_selected:
				deselect_unit()
			else:
				select_unit()

func select_unit():
	if not can_select:
		return
	is_selected = true
	$MenuPanel.visible = true

func deselect_unit():
	is_selected = false
	clear_highlights()
	$MenuPanel.visible = false
	can_move = false
	var managers = get_tree().get_nodes_in_group("turn_manager")
	if managers.size() > 0:
		var manager = managers[0]
		if manager.selected_unit == self:
			manager.selected_unit = null

func _unhandled_input(event):
	if not is_selected or not can_move:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos = get_global_mouse_position()
		var cell_clicked = Vector2i(
			int(click_pos.x / tile_size),
			int(click_pos.y / tile_size)
		)
		var valid_cells = get_movable_cells()
		if cell_clicked in valid_cells:
			move_to(cell_clicked)
			deselect_unit()
			can_move = false

func move_to(new_board_pos: Vector2i):
	board_position = new_board_pos
	update_visual_position()
	var managers = get_tree().get_nodes_in_group("turn_manager")
	if managers.size() > 0:
		managers[0].unidad_actuo(self)

func atack_to(target: BaseUnit, atack_num: int):
	var atack = atack_one if atack_num == 1 else atack_two
	target.get_damage(atack["damage"] + power)

func get_damage(damage: int):
	hp -= damage
	if hp <= 0:
		kill_unit()

func kill_unit():
	queue_free()
	var managers = get_tree().get_nodes_in_group("turn_manager")
	if managers.size() > 0:
		managers[0].check_battle_end()


func update_visual_position():
	position = Vector2(board_position.x, board_position.y) * tile_size + Vector2(tile_size * 0.5, tile_size * 0.5)

func get_movable_cells() -> Array:
	var cells := []
	for x in range(-move_range, move_range + 1):
		for y in range(-move_range, move_range + 1):
			cells.append(board_position + Vector2i(x, y))
	return cells

func show_movable_tiles():
	clear_highlights()
	var cells = get_movable_cells()
	for cell in cells:
		var h = highlight_scene.instantiate()
		h.position = Vector2(cell.x, cell.y) * tile_size + Vector2(tile_size * 0.5, tile_size * 0.5)
		get_parent().add_child(h)
		highlights.append(h)
	can_move = true

func show_atack_tiles(atack_num: int):
	clear_highlights()
	var atack = atack_one if atack_num == 1 else atack_two
	var cells := []
	for x in range(-atack["range"], atack["range"] + 1):
		for y in range(-atack["range"], atack["range"] + 1):
			if abs(x) + abs(y) <= atack["range"]:
				cells.append(board_position + Vector2i(x, y))
	for cell in cells:
		var h = atack_highlight_scene.instantiate()
		h.position = Vector2(cell.x, cell.y) * tile_size + Vector2(tile_size * 0.5, tile_size * 0.5)
		get_parent().add_child(h)
		highlights.append(h)

func clear_highlights():
	for h in highlights:
		h.queue_free()
	highlights.clear()
	
func _on_boton_move_pressed():
	$MenuPanel.visible = false
	show_movable_tiles()

func _on_boton_atack_one_pressed():
	$MenuPanel.visible = false
	show_atack_tiles(1)
func _on_boton_atack_two_pressed():
	$MenuPanel.visible = false
	show_atack_tiles(2)

# Métodos para acceder/modificar hijos comunes
func set_sprite_texture(texture: Texture2D):
	if has_node("Sprite2D"):
		$Sprite2D.texture = texture

func set_collision_shape(shape: Shape2D):
	if has_node("CollisionShape2D"):
		$CollisionShape2D.shape = shape
