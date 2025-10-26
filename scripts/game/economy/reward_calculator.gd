extends Node
class_name RewardCalculator

var currency_manager: CurrencyManager
var turn_manager: TurnManager

func _ready():
	add_to_group("reward_calculator")
	
	# Obtener referencias
	await get_tree().process_frame
	
	currency_manager = get_tree().get_first_node_in_group("currency_manager")
	turn_manager = get_tree().get_first_node_in_group("turn_manager")
	
	if not currency_manager:
		push_error("❌ RewardCalculator: No encontró CurrencyManager")
	if not turn_manager:
		push_error("❌ RewardCalculator: No encontró TurnManager")
	
	print("🎯 RewardCalculator inicializado")

# CALCULAR RECOMPENSAS

func calculate_reward(level: int) -> Dictionary:
	
	var base_coins = 5 + (level * 2)
	# Bonificaciones opcionales (pueden agregarse según stats de batalla)
	var bonus_coins = 0
	
	# Bonus por equipo del jugador vivo
	if turn_manager and turn_manager.teams.size() > 0:
		var player_team = turn_manager.teams[0]
		var living_units = player_team.get_living_units().size()
		
		# +1 monedas por cada unidad viva
		bonus_coins += living_units * 1
		print("  ✅ Bonus por unidades vivas: +%d" % (living_units * 1))
	
	var total_coins = base_coins + bonus_coins
	
	var reward = {
		"base": base_coins,
		"bonus": bonus_coins,
		"total": total_coins,
		"level": level
	}
	
	return reward

# PROCESAR RECOMPENSA

func process_victory_reward(level: int) -> void:
	
	if not currency_manager:
		push_error("❌ No hay CurrencyManager para procesar recompensa")
		return
	
	var reward = calculate_reward(level)
	
	print("\n💰 === RECOMPENSA DE BATALLA ===")
	print("  📍 Nivel: %d" % reward["level"])
	print("  💵 Base: +%d monedas" % reward["base"])
	if reward["bonus"] > 0:
		print("  🎁 Bonus: +%d monedas" % reward["bonus"])
	print("  💰 TOTAL: +%d monedas" % reward["total"])
	print("================================\n")
	
	# Agregar monedas
	currency_manager.add_coins(reward["total"])
	
	# Mostrar estado final
	currency_manager.print_status()
