extends CanvasLayer
class_name ShopScreen

signal shop_closed()

@onready var panel = $Panel as PanelContainer
@onready var title_label = $Panel/VBoxContainer/TitleLabel as Label
@onready var coins_label = $Panel/VBoxContainer/CoinsLabel as Label
@onready var items_container = $Panel/VBoxContainer/ItemsContainer as HBoxContainer
@onready var continue_button = $Panel/VBoxContainer/ContinueButton as Button

@export var card_scene: PackedScene = preload("res://scenes/interfaz/UI/shop_item_card.tscn")

var shop_inventory: ShopInventory = null
var currency_manager: CurrencyManager = null
var card_scenes: Array[ShopItemCard] = []

func _ready():
	add_to_group("shop_screen")
	
	continue_button.pressed.connect(_on_continue_pressed)
	
	await get_tree().process_frame
	
	shop_inventory = run_state.shop_inventory
	currency_manager = run_state.currency_manager
	
	if not shop_inventory:
		push_error("ShopScreen: run_state.shop_inventory es nulo")
		return
	
	if not currency_manager:
		push_error("ShopScreen: run_state.currency_manager es nulo")
		return
	
	print("✅ ShopScreen inicializado")
	
	currency_manager.coins_changed.connect(_on_coins_changed)
	
	_refresh_display()

func show_shop():
	print("🛍️ ShopScreen: Mostrando tienda")
	visible = true
	_refresh_display()

func hide_shop():
	print("🛍️ ShopScreen: Ocultando tienda")
	visible = false

func _refresh_display():
	for card in card_scenes:
		card.queue_free()
	card_scenes.clear()
	
	var items = shop_inventory.get_current_items()
	
	print("🛍️ Actualizando display: %d items" % items.size())
	
	for i in range(items.size()):
		var item = items[i]
		
		var card = card_scene.instantiate() as ShopItemCard
		if not card:
			push_error("Error: card_scene.instantiate() retornó null")
			continue
		
		items_container.add_child(card)
		
		await get_tree().process_frame
		
		card.set_item(item, i)
		
		var can_afford = currency_manager.can_afford(item.cost)
		card.set_purchasable(can_afford)
		
		card.purchase_pressed.connect(_on_card_purchase_pressed)
		
		card_scenes.append(card)
		
		print("  [%d] %s - %d monedas (asequible: %s)" % [i, item.item_name, item.cost, "✅" if can_afford else "❌"])
	
	_update_coins_display()

func _update_coins_display():
	var current_coins = currency_manager.get_coins()
	coins_label.text = "Monedas: %d" % current_coins

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
	
	if shop_inventory.purchase_item(index, currency_manager):
		print("✅ Compra exitosa")
		
		var result = await item.apply_effect(get_tree().root)
		if result:
			print("✅ Efecto aplicado")
		else:
			print("⚠️ Error al aplicar efecto")
		
		_refresh_display()
	else:
		print("❌ Compra fallida")

func _on_continue_pressed():
	print("➡️ Cerrando tienda y continuando...")
	hide_shop()
	shop_closed.emit()
