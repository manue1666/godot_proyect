extends Node
class_name RangeCalculator

enum RangeType {
	SQUARE,    # Cuadrado completo (ajedrez: rey)
	X,         # Forma de X (diagonales - ajedrez: alfil)
	DIAMOND,   # Distancia Manhattan 
	CROSS,     # Solo líneas rectas (ajedrez: torre)
	CIRCLE,    # Radio circular (más realista)
	KNIGHT,    # Patrón de caballo de ajedrez
	LINE       # Línea recta en una dirección
}

# Calcula las celdas válidas basándose en el tipo de rango
static func get_cells_in_range(
	start_pos: Vector2i,
	range_val: int,
	range_type: RangeType,
	is_valid_cell: Callable = func(_cell): return true
) -> Array[Vector2i]:
	
	var cells: Array[Vector2i] = []
	
	match range_type:
		RangeType.SQUARE:
			cells = _get_square_cells(start_pos, range_val)
		RangeType.X:
			cells = _get_x_cells(start_pos, range_val)
		RangeType.DIAMOND:
			cells = _get_diamond_cells(start_pos, range_val)
		RangeType.CROSS:
			cells = _get_cross_cells(start_pos, range_val)
		RangeType.CIRCLE:
			cells = _get_circle_cells(start_pos, range_val)
		RangeType.KNIGHT:
			cells = _get_knight_cells(start_pos)
		RangeType.LINE:
			cells = _get_line_cells(start_pos, range_val)
	
	# Filtrar celdas válidas usando el callback
	var filtered_cells: Array[Vector2i] = []
	for cell in cells:
		if is_valid_cell.call(cell):
			filtered_cells.append(cell)
	
	return filtered_cells

# ============ ALGORITMOS DE RANGO ============

static func _get_square_cells(start: Vector2i, range_val: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in range(-range_val, range_val + 1):
		for y in range(-range_val, range_val + 1):
			if x == 0 and y == 0:
				continue
			cells.append(start + Vector2i(x, y))
	return cells

# Tipo X - Diagonales (como Alfil de ajedrez)
static func _get_x_cells(start: Vector2i, range_val: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	# 4 direcciones diagonales
	var diagonal_directions = [
		Vector2i(1, 1),    # Arriba-derecha
		Vector2i(1, -1),   # Abajo-derecha
		Vector2i(-1, 1),   # Arriba-izquierda
		Vector2i(-1, -1)   # Abajo-izquierda
	]
	
	for direction in diagonal_directions:
		for i in range(1, range_val + 1):
			cells.append(start + (direction * i))
	
	return cells

static func _get_diamond_cells(start: Vector2i, range_val: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in range(-range_val, range_val + 1):
		for y in range(-range_val, range_val + 1):
			var distance = abs(x) + abs(y)
			if distance > 0 and distance <= range_val:
				cells.append(start + Vector2i(x, y))
	return cells

static func _get_cross_cells(start: Vector2i, range_val: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for i in range(1, range_val + 1):
		var dirs = [Vector2i(i, 0), Vector2i(-i, 0), Vector2i(0, i), Vector2i(0, -i)]
		for dir in dirs:
			cells.append(start + dir)
	return cells

static func _get_circle_cells(start: Vector2i, range_val: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var range_squared = range_val * range_val
	for x in range(-range_val, range_val + 1):
		for y in range(-range_val, range_val + 1):
			if x == 0 and y == 0:
				continue
			if x * x + y * y <= range_squared:
				cells.append(start + Vector2i(x, y))
	return cells

static func _get_knight_cells(start: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var knight_moves = [
		Vector2i(2, 1), Vector2i(2, -1),
		Vector2i(-2, 1), Vector2i(-2, -1),
		Vector2i(1, 2), Vector2i(1, -2),
		Vector2i(-1, 2), Vector2i(-1, -2)
	]
	for move in knight_moves:
		cells.append(start + move)
	return cells

static func _get_line_cells(start: Vector2i, range_val: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var directions = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	
	for direction in directions:
		for i in range(1, range_val + 1):
			cells.append(start + (direction * i))
	
	return cells
