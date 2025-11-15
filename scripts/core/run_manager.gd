extends Node


signal level_completed(level_num: int)
signal run_completed()
signal run_failed()

@export var total_levels: int = 5
# Cambiar rutas a constantes
const MAIN_BATTLE_SCENE = "res://scenes/game/main_battle.tscn"
const SHOP_SCENE = "res://scenes/game/shop_screen.tscn"
const RESULT_SCENE = "res://scenes/game/level_result_scene.tscn"
const MENU_SCENE = "res://scenes/game/main_menu.tscn"

var transition_in_progress: bool = false

func _ready():
	print("🎮 RunManager Autoload inicializado (ID: %d)" % get_instance_id())

func start_new_run():
	if run_state.currency_manager == null:
		_initialize_managers()
	
	run_state.initialize(total_levels)
	
	print("\n🎮 === NUEVA RUN INICIADA ===")
	start_next_level()

func start_next_level():
	if transition_in_progress:
		return
	
	run_state.advance_level()
	
	if run_state.is_run_complete():
		_show_run_complete()
		return
	
	print("\n📍 === NIVEL %d/%d ===" % [run_state.current_level, run_state.total_levels])
	
	_load_battle_scene()

func _load_battle_scene():
	if transition_in_progress:
		print("⚠️ Transición ya en progreso")
		return
	
	transition_in_progress = true
	
	print("\n🎬 === CARGANDO ESCENA DE BATALLA ===")
	print("🆔 RunManager ID: %d" % get_instance_id())
	
	# Cambiar escena
	var error = get_tree().change_scene_to_file(MAIN_BATTLE_SCENE)
	if error != OK:
		push_error("❌ Error al cargar batalla: %d" % error)
		transition_in_progress = false
		return
	
	# Esperar a que la escena se cargue
	await get_tree().process_frame
	await get_tree().tree_changed
	await get_tree().process_frame
	
	# Verificar que estamos en la escena correcta
	var current_scene = get_tree().current_scene
	if not current_scene:
		push_error("❌ No hay escena actual después del cambio")
		transition_in_progress = false
		return
	
	print("✅ Escena cargada: %s" % current_scene.name)
	
	# Configurar batalla
	call_deferred("_setup_battle_scene")

func _setup_battle_scene():
	print("\n⚙️ === CONFIGURANDO BATALLA ===")
	print("🆔 RunManager ID: %d" % get_instance_id())
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# VERIFICACIÓN DE GRUPOS
	print("\n🔍 Verificando grupos en escena actual:")
	for node in get_tree().get_nodes_in_group("map_generator"):
		print("  ✅ MapGenerator encontrado: %s" % node.name)
	for node in get_tree().get_nodes_in_group("enemy_spawner"):
		print("  ✅ EnemySpawner encontrado: %s" % node.name)
	for node in get_tree().get_nodes_in_group("enemy_team"):
		print("  ✅ EnemyTeam encontrado: %s" % node.name)
	for node in get_tree().get_nodes_in_group("player_team"):
		print("  ✅ PlayerTeam encontrado: %s" % node.name)
	for node in get_tree().get_nodes_in_group("turn_manager"):
		print("  ✅ TurnManager encontrado: %s" % node.name)
	for node in get_tree().get_nodes_in_group("battle_hud"):
		print("  ✅ BattleHUD encontrado: %s" % node.name)
	
	# 1. BUSCAR COMPONENTES
	var turn_manager = get_tree().get_first_node_in_group("turn_manager")
	var enemy_spawner = get_tree().get_first_node_in_group("enemy_spawner")
	var map_generator = get_tree().get_first_node_in_group("map_generator")
	var battle_hud = get_tree().get_first_node_in_group("battle_hud")
	
	print("\n📋 Paso 1: Buscando componentes...")
	print("  · TurnManager: %s (ID: %d)" % ["✅" if turn_manager else "❌", turn_manager.get_instance_id() if turn_manager else 0])
	print("  · EnemySpawner: %s" % ["✅" if enemy_spawner else "❌"])
	print("  · MapGenerator: %s" % ["✅" if map_generator else "❌"])
	print("  · BattleHUD: %s" % ["✅" if battle_hud else "❌"])
	
	if not turn_manager or not enemy_spawner or not map_generator:
		push_error("❌ Componentes críticos no encontrados")
		transition_in_progress = false
		return
	
	# 2. CONECTAR SEÑAL DE BATALLA TERMINADA
	print("\n📋 Paso 2: Conectando señal battle_ended...")
	if not turn_manager.battle_ended.is_connected(_on_battle_ended):
		turn_manager.battle_ended.connect(_on_battle_ended)
		print("  ✅ Señal conectada")
	else:
		print("  ⚠️ Señal ya estaba conectada")
	
	# 3. GENERAR ENEMIGOS
	print("\n📋 Paso 3: Generando enemigos...")
	var enemy_team = get_tree().get_first_node_in_group("enemy_team")
	
	if not enemy_team:
		push_error("❌ enemy_team no encontrado")
		transition_in_progress = false
		return
	
	run_state.enemy_team = enemy_team
	enemy_spawner.spawn_enemies_for_level(run_state.current_level, enemy_team)
	
	await get_tree().process_frame
	print("  ✅ Enemigos generados: %d" % enemy_team.units.size())
	
	# 4. BUSCAR EQUIPOS EN TURN_MANAGER
	print("\n📋 Paso 4: Verificando equipos en TurnManager...")
	
	# Forzar búsqueda de equipos
	if turn_manager.teams.is_empty():
		turn_manager._search_for_teams()
	
	await get_tree().process_frame
	
	if turn_manager.teams.size() < 2:
		push_error("❌ TurnManager no tiene suficientes equipos: %d" % turn_manager.teams.size())
		transition_in_progress = false
		return
	
	print("  ✅ TurnManager tiene %d equipos" % turn_manager.teams.size())
	for i in range(turn_manager.teams.size()):
		var team = turn_manager.teams[i]
		print("    [%d] %s - %d unidades" % [i, team.team_name, team.units.size()])
	
	# 5. VALIDAR EQUIPOS
	print("\n📋 Paso 5: Validando equipos...")
	var player_team = turn_manager.teams[0] if turn_manager.teams.size() > 0 else null
	enemy_team = turn_manager.teams[1] if turn_manager.teams.size() > 1 else null
	
	if not player_team or not enemy_team:
		push_error("❌ Faltan equipos")
		transition_in_progress = false
		return
	
	run_state.player_team = player_team
	run_state.enemy_team = enemy_team
	
	print("  ✅ Player team: %d unidades" % player_team.units.size())
	print("  ✅ Enemy team: %d unidades" % enemy_team.units.size())
	
	# 6. RESETEAR UNIDADES
	print("\n📋 Paso 6: Reseteando unidades...")
	turn_manager.reset_all_units_for_new_battle()
	await get_tree().process_frame
	print("  ✅ Unidades reseteadas")
	
	# 7. GENERAR MAPA
	print("\n📋 Paso 7: Generando mapa...")
	map_generator.generate_new_map()
	
	# Esperar a que el mapa se genere
	
	# ⚠️ CRUCIAL: Esperar frames adicionales para posicionamiento
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("\n📋 Paso 8: Conectando BattleHUD...")
	
	# 8. CONECTAR BATTLE_HUD
	if battle_hud and turn_manager.has_signal("unit_selected"):
		if not turn_manager.unit_selected.is_connected(battle_hud._on_unit_selected):
			turn_manager.unit_selected.connect(battle_hud._on_unit_selected)
			print("  ✅ BattleHUD conectado a unit_selected")
		else:
			print("  ⚠️ BattleHUD ya estaba conectado")
	
	#	CONECTAR BOTÓN END TURN
	if battle_hud and battle_hud.has_signal("end_turn_pressed"):
		if not battle_hud.end_turn_pressed.is_connected(turn_manager.end_turn):
			battle_hud.end_turn_pressed.connect(turn_manager.end_turn)
			print("  ✅ Botón End Turn conectado a TurnManager")
		else:
			print("  ⚠️ End Turn ya estaba conectado")
	
	# 9. INICIAR BATALLA
	print("\n📋 Paso 9: INICIANDO BATALLA...")
	print("DEBUG: TurnManager antes de begin_battle():")
	print("  · ID: %d" % turn_manager.get_instance_id())
	print("  · is_battle_started: %s" % turn_manager.is_battle_started)
	print("  · teams.size(): %d" % turn_manager.teams.size())
	print("  · is_inside_tree(): %s" % turn_manager.is_inside_tree())
	
	# Verificar que está en el árbol
	if not turn_manager.is_inside_tree():
		push_error("❌ TurnManager NO está en el árbol")
		transition_in_progress = false
		return
	
	#	LLAMAR begin_battle()
	turn_manager.begin_battle()
	
	# Esperar propagación
	await get_tree().process_frame
	
	print("\nDEBUG: TurnManager después de begin_battle():")
	print("  · is_battle_started: %s" % turn_manager.is_battle_started)
	print("  · current_team_index: %d" % turn_manager.current_team_index)
	
	if not turn_manager.is_battle_started:
		push_error("❌ begin_battle() NO cambió is_battle_started a true")
	else:
		print("✅ ✅ ✅ BATALLA INICIADA EXITOSAMENTE ✅ ✅ ✅")
	
	print("\n=== FIN SETUP BATALLA ===\n")
	
	transition_in_progress = false

func _on_map_generated(_map_data = null):
	print("📡 Señal map_generated recibida en RunManager")

func _on_battle_ended(winner_team: Team):
	print("\n🏁 Batalla terminada - Ganador: %s" % (winner_team.team_name if winner_team else "Empate"))
	
	if winner_team and winner_team.team_id == 0:
		run_state.complete_level()
		level_completed.emit(run_state.current_level)
		
		if run_state.reward_calculator:
			run_state.reward_calculator.process_victory_reward(run_state.current_level)
		
		if run_state.shop_inventory:
			run_state.shop_inventory.generate_items(run_state.current_level)
		
		_load_shop_scene()
	else:
		_load_result_scene("DEFEAT")

func _load_shop_scene():
	if transition_in_progress:
		return
	
	transition_in_progress = true
	
	print("🎬 Cargando escena de tienda...")
	get_tree().change_scene_to_file(SHOP_SCENE)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	_setup_shop_scene()

func _setup_shop_scene():
	await get_tree().process_frame
	
	var shop_screen = get_tree().get_first_node_in_group("shop_screen")
	var shop_inventory = get_tree().get_first_node_in_group("shop_inventory")
	var currency_manager = get_tree().get_first_node_in_group("currency_manager")
	
	if not shop_screen:
		push_error("ShopScreen no encontrado")
		transition_in_progress = false
		return
	
	if shop_inventory:
		run_state.shop_inventory = shop_inventory
	
	if currency_manager:
		run_state.currency_manager = currency_manager
	
	shop_screen.shop_closed.connect(_on_shop_closed)
	
	print("✅ Escena de tienda lista")
	shop_screen.show_shop()
	
	transition_in_progress = false

func _on_shop_closed():
	print("🛍️ Tienda cerrada, aplicando boosts...")
	
	if run_state.team_stats_tracker and run_state.player_team:
		run_state.team_stats_tracker.apply_all_boosts_to_team(run_state.player_team)
	
	await get_tree().create_timer(0.5).timeout
	
	start_next_level()

func _load_result_scene(result_type: String):
	if transition_in_progress:
		return
	
	transition_in_progress = true
	
	print("🎬 Cargando escena de resultados...")
	
	var result_scene_inst = load(RESULT_SCENE).instantiate()
	get_tree().root.add_child(result_scene_inst)
	
	await get_tree().process_frame
	
	var level_result = get_tree().get_first_node_in_group("level_result_screen")
	
	if level_result:
		var units_alive = run_state.player_team.get_living_units().size() if run_state.player_team else 0
		var total_units = run_state.player_team.units.size() if run_state.player_team else 0
		
		if result_type == "DEFEAT":
			_reset_on_defeat()
			level_result.show_result(
				LevelResultScreen.ResultType.DEFEAT,
				run_state.current_level,
				run_state.total_levels,
				units_alive,
				total_units
			)
			level_result.menu_pressed.connect(_on_result_menu)
		elif result_type == "RUN_COMPLETE":
			level_result.show_result(
				LevelResultScreen.ResultType.RUN_COMPLETE,
				run_state.total_levels,
				run_state.total_levels,
				units_alive,
				total_units
			)
			level_result.continue_pressed.connect(_on_result_play_again)
			level_result.menu_pressed.connect(_on_result_menu)
	
	transition_in_progress = false

func _show_run_complete():
	print("\n🎉 RUN COMPLETADA - %d/%d NIVELES!" % [run_state.total_levels, run_state.total_levels])
	
	if run_state.currency_manager:
		run_state.currency_manager.print_status()
	
	_load_result_scene("RUN_COMPLETE")
	run_completed.emit()

func _reset_on_defeat():
	print("💀 Derrota - Reseteando run...")
	
	if run_state.currency_manager:
		run_state.currency_manager.reset_coins()
	
	if run_state.shop_inventory:
		run_state.shop_inventory.clear_inventory()
	
	if run_state.team_stats_tracker:
		run_state.team_stats_tracker.clear()
	
	run_failed.emit()

func _on_result_menu():
	print("🏠 Volviendo al menú principal...")
	get_tree().change_scene_to_file(MENU_SCENE)

func _on_result_play_again():
	print("🔄 Iniciando nueva run...")
	start_new_run()

func _initialize_managers():
	print("Inicializando managers globales...")
	
	if run_state.currency_manager == null:
		var currency_node = Node.new()
		var currency_manager = CurrencyManager.new()
		currency_manager.add_to_group("currency_manager")
		currency_node.add_child(currency_manager)
		get_tree().root.add_child(currency_node)
		run_state.currency_manager = currency_manager
		print("  ✅ CurrencyManager creado")
	
	if run_state.team_stats_tracker == null:
		var tracker_node = Node.new()
		var tracker = TeamStatsTracker.new()
		tracker.add_to_group("team_stats_tracker")
		tracker_node.add_child(tracker)
		get_tree().root.add_child(tracker_node)
		run_state.team_stats_tracker = tracker
		print("  ✅ TeamStatsTracker creado")
	
	if run_state.shop_inventory == null:
		var inventory_node = Node.new()
		var inventory = ShopInventory.new()
		inventory.add_to_group("shop_inventory")
		inventory_node.add_child(inventory)
		get_tree().root.add_child(inventory_node)
		run_state.shop_inventory = inventory
		print("  ✅ ShopInventory creado")
	
	if run_state.reward_calculator == null:
		var calculator_node = Node.new()
		var calculator = RewardCalculator.new()
		calculator.add_to_group("reward_calculator")
		calculator_node.add_child(calculator)
		get_tree().root.add_child(calculator_node)
		run_state.reward_calculator = calculator
		print("  ✅ RewardCalculator creado")
	
	print("✅ Todos los managers inicializados\n")
