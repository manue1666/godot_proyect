extends Node
class_name MovementComponent

signal moved(new_position: Vector2i)

var tile_size: int = 32
@export var movement_data: MovementData = MovementData.new()

var owner_unit: BaseUnit
var is_slowed: bool = false
var current_range_boost: int = 0

func _ready():
	owner_unit = get_parent() as BaseUnit
	if not owner_unit:
		push_error("MovementComponent debe ser hijo de BaseUnit")
		return
	
	# Asegurar que hay datos de movimiento
	if not movement_data or not movement_data.is_valid():
		movement_data = MovementData.new()
	
	print("🚶 MovementComponent: tipo=%s, rango_base=%d" % [
		MovementData.MovementType.keys()[movement_data.movement_type],
		movement_data.base_range
	])

func apply_slow():
	is_slowed = true
	print("🐌 Movimiento ralentizado")

func remove_slow():
	is_slowed = false
	print("✅ Efecto lentitud finalizado")

func get_movable_cells() -> Array[Vector2i]:
	var current_range = _calculate_current_range()
	var range_calculator_type = movement_data.get_range_calculator_type()
	var start_pos = owner_unit.board_position
	
	# Usar RangeCalculator con callback personalizado según el tipo de movimiento
	match movement_data.range_type:
		MovementData.MovementRangeType.STANDARD:
			return RangeCalculator.get_cells_in_range(
				start_pos,
				current_range,
				range_calculator_type,
				is_cell_walkable
			)
		
		MovementData.MovementRangeType.FLYING:
			return RangeCalculator.get_cells_in_range(
				start_pos,
				current_range,
				range_calculator_type,
				func(cell): return is_cell_valid(cell) and is_cell_free(cell)
			)
		
		MovementData.MovementRangeType.TELEPORT:
			return _get_teleport_cells(start_pos)
		
		_:
			return RangeCalculator.get_cells_in_range(
				start_pos,
				current_range,
				range_calculator_type,
				is_cell_walkable
			)

func _calculate_current_range() -> int:
	var base_range = movement_data.base_range + current_range_boost
	
	if is_slowed:
		return 1
	
	return base_range

#acceder al rango actual
func get_current_range() -> int:
	return _calculate_current_range()

# Aplicar boost desde el valor base
func set_range_boost(boost: int):
	current_range_boost = boost
	print("  🚶 Rango recalculado: %d (base) + %d (boost) = %d" % [
		movement_data.base_range,
		boost,
		_calculate_current_range()
	])

# Resetear al original
func reset_range():
	current_range_boost = 0
	print("  🔄 Rango reseteado: %d" % _calculate_current_range())

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
	if not owner_unit.has_node("AnimatedSprite2D"):
		return
	
	var sprite = owner_unit.get_node("AnimatedSprite2D") as AnimatedSprite2D
	if direction.x < 0:
		sprite.flip_h = true
	elif direction.x > 0:
		sprite.flip_h = false

# VALIDACIONES

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
