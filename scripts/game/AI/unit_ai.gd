class_name UnitAI

var unit: BaseUnit
var turn_manager: TurnManager
var decision_maker: AIDecisionMaker
var strategies: AIStrategies

func _init(p_unit: BaseUnit, p_turn_manager: TurnManager):
	unit = p_unit
	turn_manager = p_turn_manager
	decision_maker = AIDecisionMaker.new(unit, turn_manager)
	strategies = AIStrategies.new(unit, turn_manager)

func take_action() -> void:
	print("🎯 %s tomando decisión..." % unit.name)
	
	if not unit.state_machine.can_act():
		print("  ⚠️ %s no está en estado válido" % unit.name)
		return
	
	# Usar decision_maker
	var action = decision_maker.decide_action()
	
	if action:
		# Ejecutar estrategia elegida
		await strategies.execute_strategy(action)
	else:
		print("  ❌ No se pudo decidir acción")
	
	print("  ✅ %s terminó su turno" % unit.name)
	unit.state_machine.change_state(UnitStateMachine.State.EXHAUSTED)

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
