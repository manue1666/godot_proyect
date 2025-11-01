extends Node
class_name EnemySpawner


var enemy_team: Team
var turn_manager: TurnManager

func _ready():
	add_to_group("enemy_spawner")
	
	# ENCONTRAR TURN MANAGER Y EL EQUIPO ENEMIGO
	await get_tree().process_frame
	
	turn_manager = get_tree().get_first_node_in_group("turn_manager")
	
	if not turn_manager:
		push_error("❌ TurnManager no encontrado en EnemySpawner")
		return
	
	# El equipo enemigo es el segundo equipo (índice 1)
	if turn_manager.teams.size() >= 2:
		enemy_team = turn_manager.teams[1]
		print("✅ EnemySpawner conectado a equipo enemigo: %s" % enemy_team.team_name)
	else:
		push_error("❌ No hay suficientes equipos en TurnManager")

func spawn_enemies_for_level(level: int):
	if not enemy_team:
		push_error("❌ enemy_team no está disponible")
		return
	
	# Limpiar enemigos anteriores
	_clear_enemies()
	
	# Calcular cuántos enemigos según nivel
	var enemy_count = 2 + int(level / 5.0)  # 2 en nivel 1, 3 en nivel 6, etc
	enemy_count = min(enemy_count, 4)  # Máximo 4 enemigos
	
	print("\n🤖 === GENERANDO %d ENEMIGOS PARA NIVEL %d ===" % [enemy_count, level])
	
	for i in range(enemy_count):
		var enemy = _create_random_enemy()
		enemy_team.add_unit(enemy)
		print("  ✅ Enemigo %d creado: %s" % [i + 1, enemy.name])
	
	# ESPERAR UN FRAME para que _ready() se ejecute en las nuevas unidades
	await get_tree().process_frame
	
	# CONECTAR SEÑALES DE LOS NUEVOS ENEMIGOS
	_connect_enemy_signals()
	
	print("🤖 === ENEMIGOS GENERADOS Y CONECTADOS ===\n")

func _create_random_enemy() -> BaseUnit:
	var unit_id = UnitCatalog.get_random_id()
	var scene = UnitCatalog.get_scene(unit_id)
	var enemy = scene.instantiate() as BaseUnit
	enemy_team.add_child(enemy)
	
	var unit_count = enemy_team.units.size()
	enemy.name = "%s_%d" % [unit_id, unit_count]
	
	return enemy

func _clear_enemies():
	if not enemy_team:
		return
	
	# VALIDAR ANTES DE ACCEDER
	for unit in enemy_team.units.duplicate():
		if is_instance_valid(unit):
			unit.queue_free()
	
	enemy_team.units.clear()
	print("🧹 Enemigos anteriores limpiados")

# CONECTAR SEÑALES DE LOS NUEVOS ENEMIGOS AL TURN MANAGER
func _connect_enemy_signals():
	if not turn_manager:
		push_error("❌ TurnManager no disponible para conectar señales")
		return
	
	print("🔗 Conectando señales de enemigos...")
	var units_connected = 0
	
	for unit in enemy_team.get_living_units():
		if unit and is_instance_valid(unit):
			print("  · Conectando: %s" % unit.name)
			turn_manager.connect_unit_signals(unit)
			units_connected += 1
	
	print("✅ %d señales conectadas\n" % units_connected)
