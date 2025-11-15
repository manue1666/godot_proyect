extends Node
class_name RewardCalculator

func _ready():
	add_to_group("reward_calculator")
	print("RewardCalculator inicializado")

func calculate_reward(level: int) -> Dictionary:
	var base_coins = 5 + (level * 2)
	var bonus_coins = 0
	
	# Bonus por equipo del jugador vivo
	if run_state and run_state.player_team:
		var living_units = run_state.player_team.get_living_units().size()
		
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

func process_victory_reward(level: int) -> void:
	if not run_state or not run_state.currency_manager:
		push_error("RewardCalculator: No hay CurrencyManager para procesar recompensa")
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
	run_state.currency_manager.add_coins(reward["total"])
	
	# Mostrar estado final
	run_state.currency_manager.print_status()
