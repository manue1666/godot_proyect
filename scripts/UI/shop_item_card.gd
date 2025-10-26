extends PanelContainer
class_name ShopItemCard

signal purchase_pressed(index: int)

@onready var name_label = $VBoxContainer/NameLabel as Label
@onready var description_label = $VBoxContainer/DescriptionLabel as Label
@onready var cost_label = $VBoxContainer/CostLabel as Label
@onready var purchase_button = $VBoxContainer/PurchaseButton as Button

var item: ShopItem = null
var card_index: int = 0

func _ready():
	# Conectar botón
	purchase_button.pressed.connect(_on_purchase_button_pressed)

func set_item(p_item: ShopItem, p_index: int):
	item = p_item
	card_index = p_index
	
	if not item:
		push_error("❌ ShopItemCard: item nulo")
		return
	
	# Actualizar interfaz
	if item.item_type == "booster":
		name_label.text = "📦 %s" % item.item_name
	else:
		name_label.text = "👾 %s" % item.item_name
	
	description_label.text = item.description
	cost_label.text = "💰 Costo: %d monedas" % item.cost

func set_purchasable(can_purchase: bool):
	purchase_button.disabled = not can_purchase

func _on_purchase_button_pressed():
	purchase_pressed.emit(card_index)
	print("🛒 Botón de compra presionado para item index: %d" % card_index)
