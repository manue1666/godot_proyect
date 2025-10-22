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
	
	# ⭐ NUEVA LÓGICA: Evaluar situación y decidir estrategia
	var enemies = get_nearby_enemies(5)
	
	if enemies.is_empty():
		print("  ➡️ Sin enemigos cercanos, moviendo aleatoriamente")
		await do_random_movement()
	else:
		var closest_enemy = enemies[0]  # Ya está ordenado por distancia
		var _distance = unit.board_position.distance_to(closest_enemy.board_position)
		
		# ⭐ ESTRATEGIA 1: Enemigo EN RANGO DE ATAQUE
		if is_in_attack_range(closest_enemy):
			print("  ⚔️ Estrategia 1: Enemigo en rango de ataque")
			await strategy_attack_and_retreat(closest_enemy)
		
		# ⭐ ESTRATEGIA 2: Enemigo EN RANGO DE MOVIMIENTO
		elif is_in_movement_range(closest_enemy):
			print("  🚶 Estrategia 2: Movimiento hacia enemigo")
			await strategy_move_and_attack(closest_enemy)
		
		# ⭐ ESTRATEGIA 3: Enemigo LEJANO
		else:
			print("  📍 Estrategia 3: Persiguiendo enemigo lejano")
			await strategy_pursue_distant_enemy(closest_enemy)
	
	# Terminar turno
	print("  ✅ %s terminó su turno" % unit.name)
	unit.state_machine.change_state(UnitStateMachine.State.EXHAUSTED)

# ⭐ ESTRATEGIA 1: Atacar y Huir
func strategy_attack_and_retreat(target: BaseUnit) -> void:
	# Intentar atacar
	var did_attack = await try_attack_target(target)
	
	# ⭐ VALIDAR que target sigue existiendo
	if not is_instance_valid(target):
		print("    ⚠️ Target fue eliminado")
		return
	
	if did_attack and unit.state_machine.actions_available["move"]:
		# Si atacó y aún tiene movimiento, huir
		print("    💨 Huyendo después del ataque")
		await retreat_from_enemy(target)
	elif did_attack:
		print("    🛑 Atacó pero sin movimiento para huir")
	else:
		print("    ⚠️ No pudo atacar, intentando retroceder")
		await retreat_from_enemy(target)

# ⭐ ESTRATEGIA 2: Moverse adyacente y atacar
func strategy_move_and_attack(target: BaseUnit) -> void:
	# Moverse hacia enemigo
	var moved = await move_adjacent_to_target(target)
	
	# ⭐ VALIDAR que target sigue existiendo
	if not is_instance_valid(target):
		print("    ⚠️ Target fue eliminado")
		return
	
	if moved and unit.state_machine.actions_available["attack"]:
		# Si está en rango de ataque después de moverse, atacar
		if is_in_attack_range(target):
			print("    ⚔️ Atacando después de moverse")
			await try_attack_target(target)
		else:
			print("    ⚠️ Movió pero no está en rango de ataque")
	elif moved:
		print("    🛑 Movió pero sin acciones de ataque")
	else:
		print("    ⚠️ No pudo moverse, moviendo random")
		await do_random_movement()

# ⭐ ESTRATEGIA 3: Perseguir enemigo lejano
func strategy_pursue_distant_enemy(target: BaseUnit) -> void:
	# ⭐ VALIDAR que target sigue existiendo
	if not is_instance_valid(target):
		print("    ⚠️ Target fue eliminado")
		return
	
	await move_towards_target(target)

# ⭐ HELPER: Atacar y Retroceder
func retreat_from_enemy(target: BaseUnit) -> void:
	# ⭐ VALIDAR que target sigue existiendo
	if not is_instance_valid(target):
		print("    ⚠️ Target fue eliminado durante retroceso")
		return
	
	if not unit.movement_component:
		return
	
	var movable_cells = unit.movement_component.get_movable_cells()
	if movable_cells.is_empty():
		return
	
	# Encontrar celda más lejana del enemigo
	var best_cell = movable_cells[0]
	var best_distance = best_cell.distance_to(target.board_position)
	
	for cell in movable_cells:
		var distance = cell.distance_to(target.board_position)
		if distance > best_distance:
			best_distance = distance
			best_cell = cell
	
	print("    🏃 Retirándose a posición: %s" % best_cell)
	var did_move = await unit.movement_component.move_to(best_cell)
	if did_move:
		unit.state_machine.use_move_action()
		unit.moved.emit(unit, best_cell)

# ⭐ HELPER: Moverse adyacente al enemigo
func move_adjacent_to_target(target: BaseUnit) -> bool:
	# ⭐ VALIDAR que target sigue existiendo
	if not is_instance_valid(target):
		print("    ⚠️ Target fue eliminado durante movimiento")
		return false
	
	if not unit.movement_component:
		return false
	
	var movable_cells = unit.movement_component.get_movable_cells()
	if movable_cells.is_empty():
		return false
	
	# Encontrar celda adyacente más cercana al enemigo
	var best_cell = null
	var best_distance = 999
	
	for cell in movable_cells:
		# Verificar si es adyacente (distancia Manhattan = 1)
		var dx = abs(cell.x - target.board_position.x)
		var dy = abs(cell.y - target.board_position.y)
		
		if (dx + dy) <= 1:  # Adyacente
			best_cell = cell
			break
	
	# Si no hay celda adyacente, moverse lo más cerca posible
	if not best_cell:
		best_cell = movable_cells[0]
		best_distance = best_cell.distance_to(target.board_position)
		
		for cell in movable_cells:
			var distance = cell.distance_to(target.board_position)
			if distance < best_distance:
				best_distance = distance
				best_cell = cell
	
	print("    📍 Moviéndose a: %s" % best_cell)
	var did_move = await unit.movement_component.move_to(best_cell)
	
	if did_move:
		unit.state_machine.use_move_action()
		unit.moved.emit(unit, best_cell)
		return true
	
	return false

# ⭐ HELPER: Verificar si está en rango de ataque
func is_in_attack_range(target: BaseUnit) -> bool:
	# ⭐ VALIDAR que target sigue existiendo
	if not is_instance_valid(target):
		return false
	
	if not unit.attack_component:
		return false
	
	# Verificar ambos ataques
	var attack_range_1 = unit.attack_component.get_attackable_cells(0)
	var attack_range_2 = unit.attack_component.get_attackable_cells(1)
	
	return target.board_position in attack_range_1 or target.board_position in attack_range_2

# ⭐ HELPER: Verificar si está en rango de movimiento
func is_in_movement_range(target: BaseUnit) -> bool:
	# ⭐ VALIDAR que target sigue existiendo
	if not is_instance_valid(target):
		return false
	
	if not unit.movement_component:
		return false
	
	var movable_cells = unit.movement_component.get_movable_cells()
	return target.board_position in movable_cells

# --- FUNCIONES EXISTENTES ---

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
	# ⭐ VALIDAR que target sigue existiendo
	if not is_instance_valid(target):
		print("    ⚠️ Target fue eliminado durante ataque")
		return false
	
	if not unit.attack_component:
		return false
	
	var attack_range_1 = unit.attack_component.get_attackable_cells(0)
	if target.board_position in attack_range_1:
		if unit.attack_component.can_attack_target(target, 0):
			print("    ⚔️ Atacando con Ataque 1")
			await perform_ai_attack(target, 0, 1)
			return true
	
	var attack_range_2 = unit.attack_component.get_attackable_cells(1)
	if target.board_position in attack_range_2:
		if unit.attack_component.can_attack_target(target, 1):
			print("    ⚔️ Atacando con Ataque 2")
			await perform_ai_attack(target, 1, 2)
			return true
	
	return false

func perform_ai_attack(target: BaseUnit, attack_index: int, attack_num: int) -> void:
	unit.state_machine.change_state(UnitStateMachine.State.WAITING_ATTACK)
	unit.state_machine.attack_number = attack_num
	
	var did_attack = unit.attack_component.perform_attack(target, attack_index)
	
	if did_attack:
		unit.state_machine.use_attack_action()
		unit.attacked.emit(unit, target, attack_num)
		await unit.play_attack_animation(attack_num)

func move_towards_target(target: BaseUnit) -> void:
	# ⭐ VALIDAR que target sigue existiendo
	if not is_instance_valid(target):
		print("    ⚠️ Target fue eliminado durante persecución")
		return
	
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
