extends Node
class_name UnitCatalog

# CATÁLOGO DE UNIDADES

static var CATALOG = {
    "blue_ant": {
        "name": "Blue Ant",
        "description": "Balanced unit with good damage and defense",
        "cost": 8,
        "scene": "res://scenes/bugs/blue_ant.tscn",
        "rarity": "common"
    },
    "red_ant": {
        "name": "Red Ant",
        "description": "Offensive unit with decent damage",
        "cost": 12,
        "scene": "res://scenes/bugs/red_ant.tscn",
        "rarity": "common"
    },
}

# GETTERS

static func get_data(unit_id: String) -> Dictionary:
    if not CATALOG.has(unit_id):
        push_error("❌ Unidad no encontrada: %s" % unit_id)
        return {}
    return CATALOG[unit_id].duplicate()

static func get_all_ids() -> Array[String]:
    var result: Array[String] = []
    for key in CATALOG.keys():
        result.append(key)
    return result

static func get_random_id() -> String:
    var ids = get_all_ids()
    if ids.is_empty():
        push_error("❌ Catálogo de unidades vacío")
        return ""
    return ids[randi() % ids.size()]

static func get_cost(unit_id: String) -> int:
    var data = get_data(unit_id)
    return data.get("cost", 0)

static func get_scene(unit_id: String) -> PackedScene:
    var data = get_data(unit_id)
    if data.is_empty():
        return null
    return load(data["scene"])

static func get_by_rarity(rarity: String) -> Array[String]:
    var result: Array[String] = []
    for unit_id in CATALOG.keys():
        if CATALOG[unit_id].get("rarity", "common") == rarity:
            result.append(unit_id)
    return result

static func get_random_by_rarity(rarity: String) -> String:
    var units = get_by_rarity(rarity)
    if units.is_empty():
        push_warning("⚠️ No hay unidades con rareza: %s" % rarity)
        return get_random_id()  # Fallback a cualquier unidad
    return units[randi() % units.size()]

# DEBUG

static func print_all() -> void:
    print("\n📚 === CATÁLOGO DE UNIDADES ===")
    for unit_id in CATALOG.keys():
        var data = CATALOG[unit_id]
        print("  [%s] %s - %d monedas (%s)" % [unit_id, data["name"], data["cost"], data.get("rarity", "common")])
    print("  Total: %d unidades" % CATALOG.size())
    print("===============================\n")

static func print_unit(unit_id: String) -> void:
    var data = get_data(unit_id)
    if data.is_empty():
        print("❌ Unidad no encontrada: %s" % unit_id)
        return
    
    print("\n👾 === UNIDAD: %s ===" % unit_id)
    print("  Nombre: %s" % data["name"])
    print("  Descripción: %s" % data["description"])
    print("  Costo: %d monedas" % data["cost"])
    print("  Rareza: %s" % data.get("rarity", "common"))
    print("  Escena: %s" % data["scene"])
    print("============================\n")
