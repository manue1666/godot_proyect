class_name UnitAI

var unit: BaseUnit
var turn_manager: TurnManager
var tile_size: int = 32

func _init(p_unit: BaseUnit, p_turn_manager: TurnManager):
	unit = p_unit
	turn_manager = p_turn_manager

func take_action() -> void:
	print("🎯 %s tomando decisión..." % unit.name)
	
	# ASEGURAR que empieza en estado válido
	if not unit.state_machine.can_act():
		print("  ⚠️ %s no está en estado válido" % unit.name)
		return
	
	var enemies = get_nearby_enemies(5)
	
	if enemies.is_empty():
		print("  ➡️ Sin enemigos cercanos, moviendo aleatoriamente")
		await do_random_movement()
	else:
		var target = enemies[0]
		print("  🎯 Enemigo encontrado: %s a distancia %d" % [target.name, unit.board_position.distance_to(target.board_position)])
		
		var did_attack = await try_attack_target(target)
		
		if not did_attack:
			print("  🚶 Moviéndose hacia el enemigo")
			await move_towards_target(target)
	
	# ⭐ SIEMPRE terminar en EXHAUSTED
	print("  ✅ %s terminó su turno" % unit.name)
	unit.state_machine.change_state(UnitStateMachine.State.EXHAUSTED)

func get_nearby_enemies(range_val: int) -> Array[BaseUnit]:
	var enemies: Array[BaseUnit] = []
	
	if turn_manager.teams.size() < 2:
		return enemies
	
	var player_team = turn_manager.teams[0]
	
	for enemy_unit in player_team.get_living_units():
		var distance = unit.board_position.distance_to(enemy_unit.board_position)
		if distance <= range_val:
			enemies.append(enemy_unit)
	
	enemies.sort_custom(func(a, b): 
		return unit.board_position.distance_to(a.board_position) < unit.board_position.distance_to(b.board_position)
	)
	
	return enemies

func try_attack_target(target: BaseUnit) -> bool:
	if not unit.attack_component:
		return false
	
	var attack_range_1 = unit.attack_component.get_attackable_cells(0)
	if target.board_position in attack_range_1:
		if unit.attack_component.can_attack_target(target, 0):
			print("  ⚔️ Atacando con Ataque 1")
			await perform_ai_attack(target, 0, 1)
			return true
	
	var attack_range_2 = unit.attack_component.get_attackable_cells(1)
	if target.board_position in attack_range_2:
		if unit.attack_component.can_attack_target(target, 1):
			print("  ⚔️ Atacando con Ataque 2")
			await perform_ai_attack(target, 1, 2)
			return true
	
	return false

func perform_ai_attack(target: BaseUnit, attack_index: int, attack_num: int) -> void:
	unit.state_machine.change_state(UnitStateMachine.State.WAITING_ATTACK)
	unit.state_machine.attack_number = attack_num
	
	var did_attack = unit.attack_component.perform_attack(target, attack_index)
	
	if did_attack:
		unit.attacked.emit(unit, target, attack_num)
		await unit.play_attack_animation(attack_num)
	
	# NO cambiar a EXHAUSTED aquí - se hace al final de take_action()

func move_towards_target(target: BaseUnit) -> void:
	if not unit.movement_component:
		return
	
	var movable_cells = unit.movement_component.get_movable_cells()
	if movable_cells.is_empty():
		return
	
	var best_cell = movable_cells[0]
	var best_distance = best_cell.distance_to(target.board_position)
	
	for cell in movable_cells:
		var distance = cell.distance_to(target.board_position)
		if distance < best_distance:
			best_distance = distance
			best_cell = cell
	
	var did_move = await unit.movement_component.move_to(best_cell)
	if did_move:
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
		unit.moved.emit(unit, random_cell)
