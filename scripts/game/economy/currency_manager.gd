extends Node
class_name CurrencyManager

# Señales
signal coins_changed(current_coins: int, change: int)
signal coins_reset()

# Configuración
@export var max_coins: int = 9999

# Estado
var current_coins: int = 0
var coins_earned_this_run: int = 0

func _ready():
	add_to_group("currency_manager")
	print("💰 CurrencyManager inicializado")

# AGREGAR MONEDAS

func add_coins(amount: int) -> void:
	if amount <= 0:
		push_warning("⚠️ CurrencyManager: Intento de agregar cantidad negativa: %d" % amount)
		return
	
	var old_coins = current_coins
	current_coins = min(current_coins + amount, max_coins)
	coins_earned_this_run += amount
	
	var change = current_coins - old_coins
	print("💰 +%d monedas (Total: %d)" % [amount, current_coins])
	coins_changed.emit(current_coins, change)

# RESTAR MONEDAS

func remove_coins(amount: int) -> bool:
	if amount <= 0:
		push_warning("⚠️ CurrencyManager: Intento de restar cantidad negativa: %d" % amount)
		return false
	
	if current_coins < amount:
		print("❌ Monedas insuficientes: tienes %d, necesitas %d" % [current_coins, amount])
		return false
	
	var old_coins = current_coins
	current_coins -= amount
	
	var change = current_coins - old_coins
	print("💸 -%d monedas (Total: %d)" % [amount, current_coins])
	coins_changed.emit(current_coins, change)
	
	return true

# CONSULTAS

func get_coins() -> int:
	return current_coins

func get_coins_earned_this_run() -> int:
	return coins_earned_this_run

func can_afford(cost: int) -> bool:
	return current_coins >= cost

# RESET

func reset_coins() -> void:
	print("🔄 Reseteando monedas (tenías %d)" % current_coins)
	current_coins = 0
	coins_earned_this_run = 0
	coins_reset.emit()

#DEBUG 

func print_status() -> void:
	print("\n💰 === CURRENCY STATUS ===")
	print("  Monedas actuales: %d / %d" % [current_coins, max_coins])
	print("  Ganadas esta run: %d" % coins_earned_this_run)
	print("========================\n")
