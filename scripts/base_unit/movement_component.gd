extends Node
class_name MovementComponent

signal moved(new_position: Vector2i)

@export var move_range: int = 1
var tile_size: int = 32
@export var movement_type: MovementType = MovementType.DIAMOND

enum MovementType {
	SQUARE,    # Cuadrado completo (todas las casillas)
	DIAMOND,   # Distancia Manhattan (forma de diamante)
	CROSS,     # Solo líneas rectas (cruz)
	CIRCLE,    # Radio circular
	KNIGHT,    # Patrón de caballo de ajedrez
	FLYING,    # Puede pasar sobre unidades
	TELEPORT   # Puede aparecer en cualquier casilla válida
}

var owner_unit: BaseUnit

func _ready():
	owner_unit = get_parent() as BaseUnit
	if not owner_unit:
		push_error("MovementComponent debe ser hijo de BaseUnit")

func get_movable_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var start_pos = owner_unit.board_position
	
	match movement_type:
		MovementType.SQUARE:
			cells = _get_square_cells(start_pos, move_range)
		MovementType.DIAMOND:
			cells = _get_diamond_cells(start_pos, move_range)
		MovementType.CROSS:
			cells = _get_cross_cells(start_pos, move_range)
		MovementType.CIRCLE:
			cells = _get_circle_cells(start_pos, move_range)
		MovementType.KNIGHT:
			cells = _get_knight_cells(start_pos)
		MovementType.FLYING:
			cells = _get_flying_cells(start_pos, move_range)
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
			var distance = abs(x) + abs(y)  # Manhattan
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
	# Voladores usan DIAMOND pero pueden pasar sobre unidades
	var cells: Array[Vector2i] = []
	for x in range(-range_val, range_val + 1):
		for y in range(-range_val, range_val + 1):
			var distance = abs(x) + abs(y)
			if distance > 0 and distance <= range_val:
				var cell = start + Vector2i(x, y)
				# Solo validar que la casilla exista, no que esté libre
				if is_cell_valid(cell) and is_cell_free(cell):
					cells.append(cell)
	return cells

func _get_teleport_cells(start: Vector2i) -> Array[Vector2i]:
	# Teletransporte puede ir a cualquier casilla libre del tablero
	var cells: Array[Vector2i] = []
	for x in range(32):  # Tamaño del tablero
		for y in range(32):
			var cell = Vector2i(x, y)
			if cell != start and is_cell_free(cell):
				cells.append(cell)
	return cells

func move_to(target_pos: Vector2i) -> bool:
	if target_pos not in get_movable_cells():
		return false
	# Movimiento suave con tween
	owner_unit.board_position = target_pos  # Actualizar posición lógica
	var target_world_pos = Vector2(target_pos.x, target_pos.y) * tile_size + Vector2(tile_size * 0.5, tile_size * 0.5)
	# Crear tween para movimiento suave
	var mov_tween = owner_unit.create_tween()
	mov_tween.set_ease(Tween.EASE_IN_OUT)  # Suavizado
	mov_tween.set_trans(Tween.TRANS_QUAD)  # Tipo de transición
	mov_tween.tween_property(owner_unit, "position", target_world_pos, 0.3)
	
	# Esperar a que termine el movimiento
	await mov_tween.finished
	
	moved.emit(target_pos)
	return true

# Validaciones
func is_cell_valid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < 32 and cell.y >= 0 and cell.y < 32

func is_cell_free(cell: Vector2i) -> bool:
	var units = owner_unit.get_tree().get_nodes_in_group("units")
	for unit in units:
		if unit is BaseUnit and unit.board_position == cell and unit != owner_unit:
			return false
	return true

func is_cell_walkable(cell: Vector2i) -> bool:
	# RECOMENDACIÓN: Consultar TileMap para terreno en el futuro
	return is_cell_valid(cell) and is_cell_free(cell)
