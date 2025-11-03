extends Node
class_name BoosterCatalog

#   CATÁLOGO DE BOOSTERS

static var CATALOG = {
	"health": {
		"name": "Booster de Salud",
		"description": "+5 Max HP a todas\n las unidades",
		"cost": 10,
		"amount": 5,
		"type": "health"
	},
	"power": {
		"name": "Booster de Poder",
		"description": "+1 Poder a todas\n las unidades",
		"cost": 5,
		"amount": 1,
		"type": "power"
	},
	"movement": {
		"name": "Booster de Movimiento",
		"description": "+1 Rango de\n movimiento a todas\n las unidades",
		"cost": 5,
		"amount": 1,
		"type": "movement"
	},
	"full_heal": {
		"name": "Curación Completa",
		"description": "Restaura toda\n la salud de todas\n las unidades",
		"cost": 3,
		"amount": 100,
		"type": "full_heal"
	},
}

# GETTERS

static func get_data(booster_id: String) -> Dictionary:
	if not CATALOG.has(booster_id):
		push_error("❌ Booster no encontrado: %s" % booster_id)
		return {}
	return CATALOG[booster_id].duplicate()

static func get_all_ids() -> Array[String]:
	var result: Array[String] = []
	for key in CATALOG.keys():
		result.append(key)
	return result

static func get_random_id() -> String:
	var ids = get_all_ids()
	if ids.is_empty():
		push_error("❌ Catálogo de boosters vacío")
		return ""
	return ids[randi() % ids.size()]

static func get_cost(booster_id: String) -> int:
	var data = get_data(booster_id)
	return data.get("cost", 0)

static func get_by_type(booster_type: String) -> Array[String]:
	var result: Array[String] = []
	for booster_id in CATALOG.keys():
		if CATALOG[booster_id]["type"] == booster_type:
			result.append(booster_id)
	return result

# DEBUG

static func print_all() -> void:
	print("\n📚 === CATÁLOGO DE BOOSTERS ===")
	for booster_id in CATALOG.keys():
		var data = CATALOG[booster_id]
		print("  [%s] %s - %d monedas" % [booster_id, data["name"], data["cost"]])
	print("  Total: %d boosters" % CATALOG.size())
	print("===============================\n")

static func print_booster(booster_id: String) -> void:
	var data = get_data(booster_id)
	if data.is_empty():
		print("❌ Booster no encontrado: %s" % booster_id)
		return
	
	print("\n📦 === BOOSTER: %s ===" % booster_id)
	print("  Nombre: %s" % data["name"])
	print("  Descripción: %s" % data["description"])
	print("  Costo: %d monedas" % data["cost"])
	print("  Tipo: %s" % data["type"])
	print("  Cantidad: %d" % data["amount"])
	print("===========================\n")
