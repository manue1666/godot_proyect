extends Node

class_name AIStrategies

var unit: BaseUnit
var turn_manager: TurnManager

func _init(p_unit: BaseUnit, p_turn_manager: TurnManager):
	unit = p_unit
	turn_manager = p_turn_manager

func execute_strategy(action: Dictionary) -> void:
	# Ejecuta la estrategia elegida
	print("🎬 Ejecutando estrategia: %s" % action["type"])
	var target = action.get("target")
	print("   Target: %s" % (target.name if target else "null"))
	
	match action["type"]:
		"attack":
			await strategy_attack(target)
		"move":
			await strategy_move(target)
		"retreat":
			await strategy_retreat(target)
		"pursue":
			await strategy_pursue(target)
		"random":
			await strategy_random()
		_:
			push_error("Estrategia desconocida: %s" % action["type"])

# ESTRATEGIAS
func strategy_attack(target: BaseUnit) -> void:
	if not is_instance_valid(target):
		return
	print("    ⚔️ Ejecutando: ATAQUE a %s" % target.name)
	# Intentar atacar
	if not unit.attack_component:
		return
	
	var attack_range_1 = unit.attack_component.get_attackable_cells(0)
	if target.board_position in attack_range_1:
		if unit.attack_component.can_attack_target(target, 0):
			await perform_ai_attack(target, 0, 1)
			return
	
	var attack_range_2 = unit.attack_component.get_attackable_cells(1)
	if target.board_position in attack_range_2:
		if unit.attack_component.can_attack_target(target, 1):
			await perform_ai_attack(target, 1, 2)
			return

func strategy_move(target: BaseUnit) -> void:
	if not is_instance_valid(target):
		return
	
	print("    🚶 Ejecutando: MOVIMIENTO hacia %s" % target.name)
	await move_adjacent_to_target(target)
	
	# Si está en rango después de moverse, atacar
	if is_in_attack_range(target) and unit.state_machine.actions_available.get("attack", false):
		print("    ⚔️ Atacando después de movimiento")
		await strategy_attack(target)

func strategy_retreat(target: BaseUnit) -> void:
	if not is_instance_valid(target):
		return
	
	print("    💨 Ejecutando: RETROCESO desde %s" % target.name)
	await retreat_from_enemy(target)

func strategy_pursue(target: BaseUnit) -> void:
	if not is_instance_valid(target):
		return
	
	print("    📍 Ejecutando: PERSECUCIÓN de %s" % target.name)
	await move_towards_target(target)

func strategy_random() -> void:
	print("    🎲 Ejecutando: MOVIMIENTO ALEATORIO")
	await do_random_movement()

#ACCIONES 

func move_adjacent_to_target(target: BaseUnit) -> bool:
	if not is_instance_valid(target) or not unit.movement_component:
		return false
	
	var movable_cells = unit.movement_component.get_movable_cells()
	if movable_cells.is_empty():
		return false
	
	var best_cell = null
	
	# Buscar celda adyacente
	for cell in movable_cells:
		var dx = abs(cell.x - target.board_position.x)
		var dy = abs(cell.y - target.board_position.y)
		
		if (dx + dy) <= 1:
			best_cell = cell
			break
	
	# Si no hay adyacente, buscar más cercana
	if not best_cell:
		best_cell = movable_cells[0]
		var best_distance = best_cell.distance_to(target.board_position)
		
		for cell in movable_cells:
			var distance = cell.distance_to(target.board_position)
			if distance < best_distance:
				best_distance = distance
				best_cell = cell
	
	var did_move = await unit.movement_component.move_to(best_cell)
	
	if did_move:
		unit.state_machine.use_move_action()
		unit.moved.emit(unit, best_cell)
		return true
	
	return false

func retreat_from_enemy(target: BaseUnit) -> void:
	if not is_instance_valid(target) or not unit.movement_component:
		return
	
	var movable_cells = unit.movement_component.get_movable_cells()
	if movable_cells.is_empty():
		return
	
	# Encontrar celda más lejana
	var best_cell = movable_cells[0]
	var best_distance = best_cell.distance_to(target.board_position)
	
	for cell in movable_cells:
		var distance = cell.distance_to(target.board_position)
		if distance > best_distance:
			best_distance = distance
			best_cell = cell
	
	var did_move = await unit.movement_component.move_to(best_cell)
	
	if did_move:
		unit.state_machine.use_move_action()
		unit.moved.emit(unit, best_cell)

func move_towards_target(target: BaseUnit) -> void:
	if not is_instance_valid(target) or not unit.movement_component:
		return
	
	var movable_cells = unit.movement_component.get_movable_cells()
	if movable_cells.is_empty():
		return
	
	# Encontrar celda más cercana
	var best_cell = movable_cells[0]
	var best_distance = best_cell.distance_to(target.board_position)
	
	for cell in movable_cells:
		var distance = cell.distance_to(target.board_position)
		if distance < best_distance:
			best_distance = distance
			best_cell = cell
	
	var did_move = await unit.movement_component.move_to(best_cell)
	
	if did_move:
		unit.state_machine.use_move_action()
		unit.moved.emit(unit, best_cell)

func do_random_movement() -> void:
	if not unit.movement_component:
		return
	
	var movable_cells = unit.movement_component.get_movable_cells()
	if movable_cells.is_empty():
		return
	
	var random_cell = movable_cells[randi() % movable_cells.size()]
	var did_move = await unit.movement_component.move_to(random_cell)
	
	if did_move:
		unit.state_machine.use_move_action()
		unit.moved.emit(unit, random_cell)

func perform_ai_attack(target: BaseUnit, attack_index: int, attack_num: int) -> void:
	unit.state_machine.change_state(UnitStateMachine.State.WAITING_ATTACK)
	unit.state_machine.attack_number = attack_num
	
	var did_attack = unit.attack_component.perform_attack(target, attack_index)
	
	if did_attack:
		unit.state_machine.use_attack_action()
		unit.attacked.emit(unit, target, attack_num)
		await unit.play_attack_animation(attack_num)

# ============ HELPERS ============

func is_in_attack_range(target: BaseUnit) -> bool:
	if not is_instance_valid(target) or not unit.attack_component:
		return false
	
	var attack_range_1 = unit.attack_component.get_attackable_cells(0)
	var attack_range_2 = unit.attack_component.get_attackable_cells(1)
	
	return target.board_position in attack_range_1 or target.board_position in attack_range_2
