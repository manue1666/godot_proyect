extends Node
class_name EnemySpawner

var turn_manager: TurnManager

func _ready():
	add_to_group("enemy_spawner")
	print("EnemySpawner inicializado")

func spawn_enemies_for_level(level: int, enemy_team: Team):
	# Validar que enemy_team fue pasado
	if not enemy_team:
		push_error("❌ enemy_team es null")
		return
	
	# Buscar TurnManager si no lo tiene
	if not turn_manager:
		turn_manager = get_tree().get_first_node_in_group("turn_manager")
	
	if not turn_manager:
		push_error("❌ TurnManager no encontrado")
		return
	
	print("\n🤖 === GENERANDO ENEMIGOS PARA NIVEL %d ===" % level)
	print("  · Enemy team: %s" % enemy_team.team_name)
	
	# Limpiar enemigos anteriores
	_clear_enemies(enemy_team)
	
	# Calcular cuántos enemigos según nivel
	var enemy_count = 2 + int(level / 5.0)
	enemy_count = min(enemy_count, 4)
	
	print("  · Generando %d enemigos..." % enemy_count)
	
	for i in range(enemy_count):
		var enemy = _create_random_enemy(enemy_team)
		if enemy:
			print("    ✅ Enemigo %d creado: %s" % [i + 1, enemy.name])
	
	# ESPERAR UN FRAME para que _ready() se ejecute en las nuevas unidades
	await get_tree().process_frame
	
	# CONECTAR SEÑALES DE LOS NUEVOS ENEMIGOS
	_connect_enemy_signals(enemy_team)
	
	print("🤖 === %d ENEMIGOS GENERADOS Y CONECTADOS ===\n" % enemy_team.units.size())

func _create_random_enemy(enemy_team: Team) -> BaseUnit:
	var unit_id = UnitCatalog.get_random_id()
	var scene = UnitCatalog.get_scene(unit_id)
	
	if not scene:
		push_error("❌ No se encontró escena para: %s" % unit_id)
		return null
	
	var enemy = scene.instantiate() as BaseUnit
	if not enemy:
		push_error("❌ Error al instanciar enemigo: %s" % unit_id)
		return null
	
	# Agregar al árbol primero
	enemy_team.add_child(enemy)
	
	# Configurar propiedades
	var unit_count = enemy_team.units.size() + 1
	enemy.name = "%s_%d" % [unit_id, unit_count]
	enemy.team_id = 1
	enemy.team = enemy_team
	
	# Agregar a la lista de unidades del equipo
	enemy_team.add_unit(enemy)
	
	return enemy

func _clear_enemies(enemy_team: Team):
	if not enemy_team:
		return
	
	print("  🧹 Limpiando enemigos anteriores...")
	
	for unit in enemy_team.units.duplicate():
		if is_instance_valid(unit):
			unit.queue_free()
	
	enemy_team.units.clear()
	print("    ✅ Enemigos limpiados")

func _connect_enemy_signals(enemy_team: Team):
	if not turn_manager:
		push_error("❌ TurnManager no disponible para conectar señales")
		return
	
	if not enemy_team:
		push_error("❌ enemy_team no disponible")
		return
	
	print("  🔗 Conectando señales de enemigos...")
	var units_connected = 0
	
	for unit in enemy_team.get_living_units():
		if unit and is_instance_valid(unit):
			turn_manager.connect_unit_signals(unit)
			units_connected += 1
	
	print("    ✅ %d señales conectadas" % units_connected)
