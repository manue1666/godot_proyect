extends Node
class_name AttackComponent

signal attack_performed(target: BaseUnit, attack_data: AttackData)

@export var attacks: Array[AttackData] = []
@export var tile_size: int = 32

var owner_unit: BaseUnit

func _ready():
	owner_unit = get_parent() as BaseUnit
	if not owner_unit:
		push_error("AttackComponent debe ser hijo de BaseUnit")

func get_attack(index: int) -> AttackData:
	if index >= 0 and index < attacks.size():
		return attacks[index]
	return null

func get_attackable_cells(attack_index: int) -> Array[Vector2i]:
	var attack = get_attack(attack_index)
	if not attack or not attack.is_valid():
		return []
	
	var cells: Array[Vector2i] = []
	var range_val = attack.range
	var start_pos = owner_unit.board_position
	
	match attack.range_type:
		AttackData.RangeType.SQUARE:
			cells = _get_square_cells(start_pos, range_val)
		AttackData.RangeType.DIAMOND:
			cells = _get_diamond_cells(start_pos, range_val)
		AttackData.RangeType.CROSS:
			cells = _get_cross_cells(start_pos, range_val)
		AttackData.RangeType.CIRCLE:
			cells = _get_circle_cells(start_pos, range_val)
		AttackData.RangeType.KNIGHT:
			cells = _get_knight_cells(start_pos)
		_:
			cells = _get_diamond_cells(start_pos, range_val)
	
	return cells

func can_attack_target(target: BaseUnit, attack_index: int) -> bool:
	if not target or target == owner_unit:
		return false
	if not owner_unit.team or not target.team:
		return false
	if not owner_unit.team.is_enemy(target.team):
		return false
	if target.state_machine.is_dead():
		return false
	
	var cells = get_attackable_cells(attack_index)
	return target.board_position in cells

func perform_attack(target: BaseUnit, attack_index: int) -> bool:
	var attack = get_attack(attack_index)
	if not attack or not can_attack_target(target, attack_index):
		return false
	
	# Calcular daño
	var damage = attack.damage + owner_unit.power
	
	# Aplicar daño
	if target.has_node("HealthComponent"):
		target.get_node("HealthComponent").take_damage(damage, owner_unit)
	else:
		target.receive_damage(damage, owner_unit)
	
	# Aplicar efectos
	if attack.effect != AttackData.Effect.NONE:
		apply_effect(target, attack)
	
	attack_performed.emit(target, attack)
	return true

func apply_effect(target: BaseUnit, attack: AttackData):
	match attack.effect:
		AttackData.Effect.POISON:
			print("🧪 %s envenenó a %s" % [owner_unit.name, target.name])
			# TODO: Implementar sistema de status effects
		AttackData.Effect.STUN:
			print("⚡ %s aturdió a %s" % [owner_unit.name, target.name])
		AttackData.Effect.HEAL:
			print("💚 %s curó a %s" % [owner_unit.name, target.name])
		AttackData.Effect.KNOCKBACK:
			print("💥 %s empujó a %s" % [owner_unit.name, target.name])
		AttackData.Effect.SLOW:
			print("🐌 %s ralentizó a %s" % [owner_unit.name, target.name])

# Métodos helper para rangos
func _get_square_cells(start: Vector2i, range_val: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in range(-range_val, range_val + 1):
		for y in range(-range_val, range_val + 1):
			if x == 0 and y == 0:
				continue
			var cell = start + Vector2i(x, y)
			if _is_cell_valid(cell):
				cells.append(cell)
	return cells

func _get_diamond_cells(start: Vector2i, range_val: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in range(-range_val, range_val + 1):
		for y in range(-range_val, range_val + 1):
			if x == 0 and y == 0:
				continue
			if abs(x) + abs(y) <= range_val:
				var cell = start + Vector2i(x, y)
				if _is_cell_valid(cell):
					cells.append(cell)
	return cells

func _get_cross_cells(start: Vector2i, range_val: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for i in range(1, range_val + 1):
		var dirs = [Vector2i(i, 0), Vector2i(-i, 0), Vector2i(0, i), Vector2i(0, -i)]
		for dir in dirs:
			var cell = start + dir
			if _is_cell_valid(cell):
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
				if _is_cell_valid(cell):
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
		if _is_cell_valid(cell):
			cells.append(cell)
	return cells

func _is_cell_valid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < 32 and cell.y >= 0 and cell.y < 32
