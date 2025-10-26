extends Resource
class_name ShopItem

# Información básica
@export var item_id: String = ""
@export var item_name: String = ""
@export var description: String = ""
@export var cost: int = 0
@export var icon: Texture2D = null
@export var item_type: String = ""  # "booster" o "unit"

# Efecto del item
var effect: Dictionary = {}

func _init(p_id: String = "", p_name: String = "", p_cost: int = 0, p_description: String = ""):
	item_id = p_id
	item_name = p_name
	cost = p_cost
	description = p_description

# METODOS VIRTUALES

func apply_effect(_game_manager: Node) -> bool:
	# Aplica el efecto del item. Sobreescribir en subclases
	push_warning("⚠️ apply_effect() no implementado para %s" % item_name)
	return false

func can_apply() -> bool:
	# Verifica si el item puede ser aplicado. Sobreescribir si es necesario
	return true

func get_display_info() -> Dictionary:
	# Retorna información para mostrar en UI
	return {
		"name": item_name,
		"description": description,
		"cost": cost,
		"icon": icon,
		"type": item_type
	}

# DEBUG

func print_info() -> void:
	print("\n📦 === ITEM: %s ===" % item_name)
	print("  ID: %s" % item_id)
	print("  Tipo: %s" % item_type)
	print("  Costo: %d monedas" % cost)
	print("  Descripción: %s" % description)
	if not effect.is_empty():
		print("  Efectos: %s" % effect)
	print("====================\n")
