extends Node
class_name MovementComponent

signal moved(new_position: Vector2i)

var move_range: int = 1
var tile_size: int = 32
@export var movement_type: MovementType = MovementType.DIAMOND

enum MovementType {
	SQUARE,
	DIAMOND,
	CROSS,
	CIRCLE,
	KNIGHT,
	FLYING,
	TELEPORT
}

var owner_unit: BaseUnit

var is_slowed: bool = false
@export var original_range: int = 2

func _ready():
	owner_unit = get_parent() as BaseUnit
	if not owner_unit:
		push_error("MovementComponent debe ser hijo de BaseUnit")

func apply_slow():
	is_slowed = true
	print("🐌 Movimiento ralentizado")

func remove_slow():
	is_slowed = false
	print("✅ Efecto lentitud finalizado")

func get_movable_cells() -> Array[Vector2i]:
	var range_val = original_range
	if is_slowed:
		range_val = 1
	var cells: Array[Vector2i] = []
	var start_pos = owner_unit.board_position
	
	match movement_type:
		MovementType.SQUARE:
			cells = _get_square_cells(start_pos, range_val)
		MovementType.DIAMOND:
			cells = _get_diamond_cells(start_pos, range_val)
		MovementType.CROSS:
			cells = _get_cross_cells(start_pos, range_val)
		MovementType.CIRCLE:
			cells = _get_circle_cells(start_pos, range_val)
		MovementType.KNIGHT:
			cells = _get_knight_cells(start_pos)
		MovementType.FLYING:
			cells = _get_flying_cells(start_pos, range_val)
		MovementType.TELEPORT:
			cells = _get_teleport_cells(start_pos)
	
	return cells

func _get_square_cells(start: Vector2i, range_val: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in range(-range_val, range_val + 1):
		for y in range(-range_val, range_val + 1):
			if x == 0 and y == 0:
				continue
			var cell = start + Vector2i(x, y)
			if is_cell_walkable(cell):
				cells.append(cell)
	return cells

func _get_diamond_cells(start: Vector2i, range_val: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in range(-range_val, range_val + 1):
		for y in range(-range_val, range_val + 1):
			var distance = abs(x) + abs(y)
			if distance > 0 and distance <= range_val:
				var cell = start + Vector2i(x, y)
				if is_cell_walkable(cell):
					cells.append(cell)
	return cells

func _get_cross_cells(start: Vector2i, range_val: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for i in range(1, range_val + 1):
		var dirs = [Vector2i(i, 0), Vector2i(-i, 0), Vector2i(0, i), Vector2i(0, -i)]
		for dir in dirs:
			var cell = start + dir
			if is_cell_walkable(cell):
				cells.append(cell)
	return cells

func _get_circle_cells(start: Vector2i, range_val: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var range_squared = range_val * range_val
	for x in range(-range_val, range_val + 1):
		for y in range(-range_val, range_val + 1):
			if x == 0 and y == 0:
				continue
			if x * x + y * y <= range_squared:
				var cell = start + Vector2i(x, y)
				if is_cell_walkable(cell):
					cells.append(cell)
	return cells

func _get_knight_cells(start: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var knight_moves = [
		Vector2i(2, 1), Vector2i(2, -1),
		Vector2i(-2, 1), Vector2i(-2, -1),
		Vector2i(1, 2), Vector2i(1, -2),
		Vector2i(-1, 2), Vector2i(-1, -2)
	]
	for move in knight_moves:
		var cell = start + move
		if is_cell_walkable(cell):
			cells.append(cell)
	return cells

func _get_flying_cells(start: Vector2i, range_val: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in range(-range_val, range_val + 1):
		for y in range(-range_val, range_val + 1):
			var distance = abs(x) + abs(y)
			if distance > 0 and distance <= range_val:
				var cell = start + Vector2i(x, y)
				if is_cell_valid(cell) and is_cell_free(cell):
					cells.append(cell)
	return cells

func _get_teleport_cells(start: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	
	# OBTENER DIMENSIONES DEL MAPA DINÁMICAMENTE
	var map_generator = owner_unit.get_tree().get_first_node_in_group("map_generator")
	if not map_generator or not map_generator.current_map:
		print("⚠️ No hay mapa disponible para teletransporte")
		return cells
	
	var map_width = map_generator.current_map.width
	var map_height = map_generator.current_map.height

	# USAR DIMENSIONES DEL MAPA
	for x in range(map_width):
		for y in range(map_height):
			var cell = Vector2i(x, y)
			if cell != start and is_cell_free(cell) and is_cell_walkable(cell):
				cells.append(cell)
	
	return cells

func move_to(target_pos: Vector2i) -> bool:
	if target_pos not in get_movable_cells():
		return false
	
	var direction = target_pos - owner_unit.board_position
	update_sprite_direction(direction)
	
	owner_unit.board_position = target_pos
	var target_world_pos = Vector2(target_pos.x, target_pos.y) * tile_size + Vector2(tile_size * 0.5, tile_size * 0.5)
	
	var mov_tween = owner_unit.create_tween()
	mov_tween.set_ease(Tween.EASE_IN_OUT)
	mov_tween.set_trans(Tween.TRANS_QUAD)
	mov_tween.tween_property(owner_unit, "position", target_world_pos, 0.3)
	
	await mov_tween.finished
	
	moved.emit(target_pos)
	return true

func update_sprite_direction(direction: Vector2i):
	if direction.x < 0:
		owner_unit.get_node("AnimatedSprite2D").flip_h = true
	elif direction.x > 0:
		owner_unit.get_node("AnimatedSprite2D").flip_h = false

# ============ VALIDACIONES ============

func is_cell_valid(cell: Vector2i) -> bool:
	var map_generator = owner_unit.get_tree().get_first_node_in_group("map_generator")
	
	if not map_generator or not map_generator.current_map:
		return cell.x >= 0 and cell.x < 32 and cell.y >= 0 and cell.y < 32
	
	var map_width = map_generator.current_map.width
	var map_height = map_generator.current_map.height
	
	return cell.x >= 0 and cell.x < map_width and cell.y >= 0 and cell.y < map_height

func is_cell_free(cell: Vector2i) -> bool:
	var units = owner_unit.get_tree().get_nodes_in_group("units")
	for unit in units:
		if unit is BaseUnit and unit.board_position == cell and unit != owner_unit:
			return false
	return true

func is_cell_walkable(cell: Vector2i) -> bool:
	var map_generator = owner_unit.get_tree().get_first_node_in_group("map_generator")
	if map_generator and map_generator.current_map:
		if not map_generator.current_map.is_walkable(cell.x, cell.y):
			return false
	return is_cell_valid(cell) and is_cell_free(cell)
