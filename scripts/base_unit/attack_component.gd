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
	
	var range_calculator_type = _convert_attack_range_type(attack.range_type)
	var start_pos = owner_unit.board_position
	
	# Usar RangeCalculator
	return RangeCalculator.get_cells_in_range(
		start_pos,
		attack.range,
		range_calculator_type,
		_is_cell_valid
	)

# Convertir AttackData.RangeType a RangeCalculator.RangeType
func _convert_attack_range_type(attack_range_type: AttackData.RangeType) -> RangeCalculator.RangeType:
	match attack_range_type:
		AttackData.RangeType.SQUARE:
			return RangeCalculator.RangeType.SQUARE
		AttackData.RangeType.X:
			return RangeCalculator.RangeType.X
		AttackData.RangeType.DIAMOND:
			return RangeCalculator.RangeType.DIAMOND
		AttackData.RangeType.CROSS:
			return RangeCalculator.RangeType.CROSS
		AttackData.RangeType.CIRCLE:
			return RangeCalculator.RangeType.CIRCLE
		AttackData.RangeType.KNIGHT:
			return RangeCalculator.RangeType.KNIGHT
		AttackData.RangeType.LINE:
			return RangeCalculator.RangeType.LINE
		_:
			return RangeCalculator.RangeType.DIAMOND

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
	if not attack or not attack.is_valid():
		return false
	
	# GIRAR SPRITE HACIA EL OBJETIVO
	_face_target(target)
	
	var damage = attack.damage + owner_unit.power
	
	# DIFERENCIACIÓN POR TIPO DE ATAQUE
	if attack.attack_type == AttackData.AttackType.AREA:
		return _perform_area_attack(attack, damage)
	else:
		return _perform_single_attack(target, attack, damage, attack_index)

func _perform_single_attack(target: BaseUnit, attack: AttackData, damage: int, attack_index: int) -> bool:
	if not target or not can_attack_target(target, attack_index):
		return false
	
	match attack.attack_type:
		AttackData.AttackType.PHYSICAL:
			_perform_physical_attack(target, attack, damage)
		
		AttackData.AttackType.RANGED:
			_perform_ranged_attack(target, attack, damage)
		
		_:
			return false
	
	attack_performed.emit(target, attack)
	return true

#	FÍSICO - Animación paralela
func _perform_physical_attack(target: BaseUnit, attack: AttackData, damage: int) -> void:
	if not _has_line_of_sight(target):
		print("❌ %s no tiene línea recta a %s" % [owner_unit.name, target.name])
		return
	
	print("⚔️ PHYSICAL: %s ataca a %s por %d de daño" % [owner_unit.name, target.name, damage])
	
	# 📍 Guardar posición original
	var original_pos = owner_unit.position
	var target_pos = target.position
	
	# 🏃 Animar acercamiento (NO ESPERAR)
	var approach_pos = original_pos.lerp(target_pos, 0.7)
	var move_tween = create_tween()
	move_tween.tween_property(owner_unit, "position", approach_pos, 0.3)
	move_tween.tween_callback(func(): 
		# Aplicar daño cuando llega
		target.receive_damage(damage, owner_unit)
		if attack.effect != AttackData.Effect.NONE:
			apply_effect(target, attack)
	)
	move_tween.tween_property(owner_unit, "position", original_pos, 0.3)

# RANGED - Proyectil paralelo
func _perform_ranged_attack(target: BaseUnit, attack: AttackData, damage: int) -> void:
	print("RANGED: %s lanza ataque a %s por %d de daño" % [owner_unit.name, target.name, damage])
	
	var start_pos = owner_unit.position
	var target_pos = target.position
	
	# Lanzar proyectil (NO ESPERAR)
	var projectile = _spawn_projectile(start_pos, target_pos)
	
	# Aplicar daño cuando llega (callback)
	await get_tree().create_timer(0.4).timeout
	target.receive_damage(damage, owner_unit)
	
	if attack.effect != AttackData.Effect.NONE:
		apply_effect(target, attack)
	
	if projectile:
		projectile.queue_free()

# Validar línea recta sin obstáculos
func _has_line_of_sight(target: BaseUnit) -> bool:
	var start = owner_unit.board_position
	var end = target.board_position
	var direction = (end - start)
	
	# Si no es línea recta diagonal/vertical/horizontal → no hay visión
	if not _is_straight_line(start, end):
		return false
	
	# Recorrer cada celda en el camino
	var normalized_dir = Vector2(direction).normalized()
	var distance = int(start.distance_to(end))
	
	for i in range(1, distance):
		var check_pos = start + Vector2i((normalized_dir * i).round())
		
		# Verificar si hay unidad bloqueando (excepto el objetivo)
		var blocking_unit = owner_unit.get_unit_at_cell(check_pos)
		if blocking_unit and blocking_unit != target:
			print("  ⚠️ Bloqueado por %s en %v" % [blocking_unit.name, check_pos])
			return false
	
	return true

# Verificar si es línea recta (horizontal, vertical o diagonal)
func _is_straight_line(from: Vector2i, to: Vector2i) -> bool:
	var delta = (to - from).abs()
	
	# Horizontal o vertical
	if delta.x == 0 or delta.y == 0:
		return true
	
	# Diagonal (45 grados)
	if delta.x == delta.y:
		return true
	
	return false

# Crear proyectil visual
func _spawn_projectile(start_pos: Vector2, target_pos: Vector2) -> Node2D:
	# Crear nodo contenedor
	var projectile = Node2D.new()
	projectile.position = start_pos
	owner_unit.get_parent().add_child(projectile)
	
	# Crear sprite (círculo simple por ahora)
	var sprite = Sprite2D.new()
	sprite.texture = preload("res://sprites/UI/icons/projectile.png")
	sprite.scale = Vector2(0.5, 0.5)
	projectile.add_child(sprite)
	
	# Rotar sprite hacia dirección
	sprite.rotation = start_pos.angle_to_point(target_pos)
	
	# Animar movimiento del proyectil
	var travel_tween = create_tween()
	travel_tween.set_trans(Tween.TRANS_LINEAR)
	travel_tween.tween_property(projectile, "position", target_pos, 0.4)
	
	# Rotar proyectil durante el vuelo
	var rotate_tween = create_tween()
	rotate_tween.set_trans(Tween.TRANS_LINEAR)
	rotate_tween.tween_property(sprite, "rotation", sprite.rotation + TAU, 0.4)
	
	print("Proyectil lanzado desde %v hacia %v" % [start_pos, target_pos])
	
	return projectile

# AREA - daña a todos los objetivos en rango
func _perform_area_attack(attack: AttackData, damage: int) -> bool:
	var attackable_cells = get_attackable_cells(_get_attack_index(attack))
	var targets_hit: Array[BaseUnit] = []
	
	# Encontrar todas las unidades en el área
	var all_units = get_tree().get_nodes_in_group("units")
	for unit in all_units:
		if unit is BaseUnit and unit != owner_unit:
			if unit.board_position in attackable_cells:
				targets_hit.append(unit)
	
	# Si no hay objetivos, el ataque falla
	if targets_hit.is_empty():
		print("⚠️ %s intentó ataque de área pero no hay objetivos en rango" % owner_unit.name)
		return false
	
	# Aplicar daño a todos los objetivos
	print("💥 %s lanza ataque de ÁREA dañando a %d unidades por %d de daño" % [
		owner_unit.name,
		targets_hit.size(),
		damage
	])
	
	for target in targets_hit:
		target.receive_damage(damage, owner_unit)
		
		# Aplicar efectos
		if attack.effect != AttackData.Effect.NONE:
			apply_effect(target, attack)
		
		print("  └─ 💢 %s recibió daño" % target.name)
		attack_performed.emit(target, attack)
	
	return true

# Helper para obtener el índice del ataque
func _get_attack_index(attack: AttackData) -> int:
	for i in range(attacks.size()):
		if attacks[i] == attack:
			return i
	return -1

# Nueva función para girar hacia el objetivo
func _face_target(target: BaseUnit):
	if not owner_unit.has_node("AnimatedSprite2D"):
		return
	
	var sprite = owner_unit.get_node("AnimatedSprite2D") as AnimatedSprite2D
	var direction = (target.board_position - owner_unit.board_position)
	
	# Determinar si mirar a la derecha o izquierda
	if direction.x > 0:
		sprite.flip_h = false  # Mirando a la derecha
	elif direction.x < 0:
		sprite.flip_h = true   # Mirando a la izquierda
	
	print("👀 %s gira hacia %s (dirección: %v)" % [owner_unit.name, target.name, direction])

func apply_effect(target: BaseUnit, attack: AttackData):
	# HEAL es caso especial - se aplica directamente
	if attack.effect == AttackData.Effect.HEAL:
		if target.health_component:
			target.health_component.heal(attack.damage)
			print("💚 %s curó a %s por %d HP" % [owner_unit.name, target.name, attack.damage])
		return
	
	# Otros efectos se pasan al StatusManager
	if target.status_manager:
		target.status_manager.apply_effect(attack.effect, attack.effect_duration)
	else:
		print("⚠️ %s no tiene StatusManager" % target.name)

func _is_cell_valid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < 32 and cell.y >= 0 and cell.y < 32
