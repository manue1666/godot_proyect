extends Node
class_name ShopInventory

signal items_generated(items: Array[ShopItem])
signal item_purchased(item: ShopItem)

var current_items: Array[ShopItem] = []
var purchase_history: Array[ShopItem] = []

func _ready():
	add_to_group("shop_inventory")
	print("🛍️ ShopInventory inicializado")

# GENERAR ITEMS 

func generate_items(level: int = 1) -> Array[ShopItem]:

	current_items.clear()
	
	print("\n🛍️ === GENERANDO TIENDA (Nivel %d) ===" % level)
	
	# Generar 2 boosters random
	var booster_ids = _get_random_boosters(2)
	for booster_id in booster_ids:
		var item = BoosterItem.new(booster_id)
		current_items.append(item)
		print("  🎁 Booster: %s - %d monedas" % [item.item_name, item.cost])
	
	# Generar 1 unidad random
	var unit_id = UnitCatalog.get_random_id()
	var unit_item = UnitItem.new(unit_id)
	current_items.append(unit_item)
	print("  👾 Unidad: %s - %d monedas" % [unit_item.item_name, unit_item.cost])
	
	print("================================\n")
	
	items_generated.emit(current_items)
	return current_items

# OBTENER ITEMS

func get_current_items() -> Array[ShopItem]:
	# Retorna los items actuales de la tienda
	return current_items

func get_item_at(index: int) -> ShopItem:
	# Retorna un item por índice
	if index < 0 or index >= current_items.size():
		push_error("❌ Índice inválido: %d" % index)
		return null
	return current_items[index]

func get_items_count() -> int:
	return current_items.size()

# COMPRAR ITEMS

func purchase_item(index: int, currency_manager: CurrencyManager) -> bool:

	var item = get_item_at(index)
	if not item:
		return false
	
	print("\n🛒 === INTENTANDO COMPRA ===")
	print("  Item: %s" % item.item_name)
	print("  Costo: %d monedas" % item.cost)
	print("  Monedas disponibles: %d" % currency_manager.get_coins())
	
	# Verificar si hay suficientes monedas
	if not currency_manager.can_afford(item.cost):
		print("  ❌ Monedas insuficientes")
		return false
	
	# Restar monedas
	if not currency_manager.remove_coins(item.cost):
		print("  ❌ Error al restar monedas")
		return false
	
	# Registrar compra
	purchase_history.append(item)
	current_items.remove_at(index)
	
	print("  ✅ Compra exitosa")
	print("  Monedas restantes: %d\n" % currency_manager.get_coins())
	
	item_purchased.emit(item)
	return true


# APLICAR ITEMS

func apply_item(index: int, game_manager: Node) -> bool:
	var item = get_item_at(index)
	if not item:
		return false
	
	var currency_manager = game_manager.get_tree().get_first_node_in_group("currency_manager")
	if not currency_manager:
		push_error("❌ No hay CurrencyManager")
		return false
	
	# Comprar
	if not purchase_item(index, currency_manager):
		return false
	
	# Aplicar efecto
	if not item.apply_effect(game_manager):
		push_error("❌ Error al aplicar efecto de item")
		return false
	
	return true

# HELPERS

func _get_random_boosters(count: int) -> Array[String]:
	# Retorna array de IDs de boosters random sin repetidos
	var all_booster_ids = BoosterCatalog.get_all_ids()
	var result: Array[String] = []
	
	if count >= all_booster_ids.size():
		return all_booster_ids  # Retornar todos si piden más de los disponibles
	
	# Shuffle y tomar los primeros 'count'
	all_booster_ids.shuffle()
	for i in range(count):
		result.append(all_booster_ids[i])
	
	return result

# DEBUG

func print_current_items() -> void:
	print("\n🛍️ === ITEMS EN TIENDA ===")
	for i in range(current_items.size()):
		var item = current_items[i]
		print("  [%d] %s - %d monedas" % [i, item.item_name, item.cost])
	print("==========================\n")

func print_purchase_history() -> void:
	print("\n📜 === HISTORIAL DE COMPRAS ===")
	for item in purchase_history:
		print("  ✅ %s - %d monedas" % [item.item_name, item.cost])
	print("  Total items comprados: %d" % purchase_history.size())
	print("================================\n")

func clear_inventory() -> void:
	current_items.clear()
	purchase_history.clear()
	print("🔄 Inventario limpiado")
