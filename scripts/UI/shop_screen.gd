extends CanvasLayer
class_name ShopScreen

signal shop_closed()

@onready var panel = $Panel as PanelContainer
@onready var title_label = $Panel/VBoxContainer/TitleLabel as Label
@onready var coins_label = $Panel/VBoxContainer/CoinsLabel as Label
@onready var items_container = $Panel/VBoxContainer/ItemsContainer as HBoxContainer
@onready var continue_button = $Panel/VBoxContainer/ContinueButton as Button

@export var card_scene: PackedScene = preload("res://scenes/interfaz/UI/shop_item_card.tscn")

var shop_inventory: ShopInventory
var currency_manager: CurrencyManager
var card_scenes: Array[ShopItemCard] = []

func _ready():
	add_to_group("shop_screen")
	
	# Conectar botones
	continue_button.pressed.connect(_on_continue_pressed)
	
	# Obtener referencias
	await get_tree().process_frame
	shop_inventory = get_tree().get_first_node_in_group("shop_inventory")
	currency_manager = get_tree().get_first_node_in_group("currency_manager")
	
	if not shop_inventory:
		push_error("❌ ShopScreen: No encontró ShopInventory")
	if not currency_manager:
		push_error("❌ ShopScreen: No encontró CurrencyManager")
	
	print("✅ ShopScreen inicializado")
	
	# Conectar señales
	if currency_manager:
		currency_manager.coins_changed.connect(_on_coins_changed)
	
	# Comenzar oculto
	visible = false

func show_shop():
	print("🛍️ ShopScreen: Mostrando tienda")
	visible = true
	_refresh_display()

func hide_shop():
	print("🛍️ ShopScreen: Ocultando tienda")
	visible = false

func _refresh_display():
	# Limpiar tarjetas anteriores
	for card in card_scenes:
		card.queue_free()
	card_scenes.clear()
	
	# Obtener items actuales
	var items = shop_inventory.get_current_items()
	
	print("🛍️ Actualizando display: %d items" % items.size())
	
	# Crear tarjeta por cada item
	for i in range(items.size()):
		var item = items[i]
		print("  📦 Creando tarjeta para: %s" % item.item_name)
		
		# Instanciar la escena
		var card = card_scene.instantiate() as ShopItemCard
		if not card:
			push_error("❌ Error: card_scene.instantiate() retornó null")
			continue
		
		print("    ✅ Tarjeta instanciada")
		
		items_container.add_child(card)
		print("    ✅ Agregada a items_container")
		
		# ESPERAR UN FRAME para que _ready() se ejecute
		await get_tree().process_frame
		print("    ✅ Frame esperado, _ready() debería haber ejecutado")
		
		# Ahora los @onready deberían estar inicializados
		card.set_item(item, i)
		print("    ✅ set_item() ejecutado")
		
		# Verificar si se puede comprar
		var can_afford = currency_manager.can_afford(item.cost)
		card.set_purchasable(can_afford)
		print("    ✅ set_purchasable() ejecutado")
		
		# Conectar señal de compra
		card.purchase_pressed.connect(_on_card_purchase_pressed)
		print("    ✅ Señal conectada")
		
		card_scenes.append(card)
		
		print("  [%d] %s - %d monedas (asequible: %s)" % [i, item.item_name, item.cost, "✅" if can_afford else "❌"])
	
	print("🛍️ Tarjetas creadas: %d" % card_scenes.size())
	
	# Actualizar etiqueta de monedas
	_update_coins_display()

func _update_coins_display():
	var current_coins = currency_manager.get_coins()
	coins_label.text = "💰 Monedas: %d" % current_coins

func _on_coins_changed(_current_coins: int, _change: int):
	_update_coins_display()
	_update_purchasable_states()

func _update_purchasable_states():
	for i in range(card_scenes.size()):
		var card = card_scenes[i]
		var item = shop_inventory.get_item_at(i)
		
		if not item:
			continue
		
		var can_afford = currency_manager.can_afford(item.cost)
		card.set_purchasable(can_afford)

func _on_card_purchase_pressed(index: int):
	print("💳 Intentando comprar item %d" % index)
	
	var item = shop_inventory.get_item_at(index)
	if not item:
		print("❌ Item no encontrado")
		return
	
	# Comprar item
	if shop_inventory.purchase_item(index, currency_manager):
		print("✅ Compra exitosa")
		
		#GREGAR AWAIT AQUÍ
		var result = await item.apply_effect(get_tree().root)
		if result:
			print("✅ Efecto aplicado")
		else:
			print("⚠️ Error al aplicar efecto")
		
		# Actualizar display
		_refresh_display()
	else:
		print("❌ Compra fallida")

func _on_continue_pressed():
	print("➡️ Cerrando tienda y continuando...")
	hide_shop()
	shop_closed.emit()

func print_status() -> void:
	print("\n🛍️ === SHOP STATUS ===")
	print("  Visible: %s" % visible)
	print("  Items mostrados: %d" % card_scenes.size())
	print("  Monedas: %d" % currency_manager.get_coins())
	print("  ======================\n")
