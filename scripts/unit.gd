extends Area2D

@export var tile_size := 32
@export var move_range := 1
@export var highlight_scene: PackedScene   # referencia a la escena Highlight.tscn

var board_position := Vector2i(3, 3)
var is_selected := false
var highlights := []  # lista de instancias de casillas resaltadas

func _ready():
	update_visual_position()
	# Asume que un TurnManager está presente en la escena (agregar uno al root o como autoload)
	connect("input_event", Callable(self, "_on_input_event"))

func _on_input_event(_viewport, event, _shape_idx):
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
	is_selected = true
	print("Unidad seleccionada")
	show_movable_tiles()

func deselect_unit():
	is_selected = false
	print("Unidad deseleccionada")
	clear_highlights()
	# Notificar al TurnManager si era la unidad seleccionada
	var managers = get_tree().get_nodes_in_group("turn_manager")
	if managers.size() > 0:
		var manager = managers[0]
		if manager.selected_unit == self:
			manager.selected_unit = null

func _unhandled_input(event):
	if not is_selected:
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

func move_to(new_board_pos: Vector2i):
	board_position = new_board_pos
	update_visual_position()
	print("Unidad movida a: ", board_position)

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

func clear_highlights():
	for h in highlights:
		h.queue_free()
	highlights.clear()
