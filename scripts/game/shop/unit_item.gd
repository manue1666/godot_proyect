extends ShopItem
class_name UnitItem
var unit_catalog : UnitCatalog

@export var unit_id: String = "blue_ant"
var unit_scene: PackedScene = null

func _init(p_id: String = "blue_ant"):
		unit_id = p_id
		item_type = "unit"
		_setup_unit()

func _setup_unit():
	var data = UnitCatalog.get_data(unit_id)
	
	if data.is_empty():
		push_error("❌ Unidad inválida: %s" % unit_id)
		return
	
	# Asignar datos del catálogo
	item_id = unit_id
	item_name = data["name"]
	description = data["description"]
	cost = data["cost"]
	
	# Cargar la escena
	unit_scene = UnitCatalog.get_scene(unit_id)
	if not unit_scene:
		push_error("❌ No se pudo cargar la escena para: %s" % unit_id)

func apply_effect(game_manager: Node) -> bool:
	
	print("\n👾 === AGREGANDO UNIDAD: %s ===" % item_name)
	
	if not unit_scene:
		push_error("❌ Unit scene no configurado")
		return false
	
	# Obtener el team del jugador
	var turn_manager = game_manager.get_tree().get_first_node_in_group("turn_manager")
	if not turn_manager or turn_manager.teams.size() == 0:
		push_error("❌ No se pudo obtener el team del jugador")
		return false
	
	var player_team = turn_manager.teams[0]
	
	# Instanciar la nueva unidad
	var new_unit = unit_scene.instantiate() as BaseUnit
	if not new_unit:
		push_error("❌ No se pudo instanciar la unidad")
		return false

	var unit_count = player_team.units.size()
	var unit_type = unit_id.to_lower()
	new_unit.name = "%s_%d" % [unit_type, unit_count]
	print("  📛 Nombre asignado: %s" % new_unit.name)
	
	# Agregar al equipo
	new_unit.team = player_team
	new_unit.team_id = player_team.team_id
	player_team.add_unit(new_unit)
	
	# Agregar a la escena (será posicionado en la siguiente batalla)
	player_team.add_child(new_unit)
	
	await game_manager.get_tree().process_frame
	
	print("  🔗 Conectando señales de nueva unidad...")
	turn_manager.connect_unit_signals(new_unit)
	
	print("  ✅ %s agregada al equipo" % item_name)
	print("  📊 Equipo ahora tiene %d unidades\n" % player_team.units.size())
	
	return true

func can_apply() -> bool:
	return true
