extends ShopItem
class_name BoosterItem

@export var booster_id: String = "health"
var booster_type: String = ""

func _init(p_id: String = "health"):
	booster_id = p_id
	item_type = "booster"
	_setup_booster()

func _setup_booster():
	var data = BoosterCatalog.get_data(booster_id)
	
	if data.is_empty():
		push_error("❌ Booster inválido: %s" % booster_id)
		return
	
	item_id = booster_id
	item_name = data["name"]
	description = data["description"]
	cost = data["cost"]
	booster_type = data["type"]
	
	effect = {
		"type": booster_type,
		"value": data["amount"]
	}

func apply_effect(game_manager: Node) -> bool:
	print("\n🎁 === APLICANDO BOOSTER: %s ===" % item_name)
	
	# Obtener tracker
	var tracker = game_manager.get_tree().get_first_node_in_group("team_stats_tracker")
	if not tracker:
		push_error("❌ No se encontró TeamStatsTracker")
		return false
	
	var amount = effect["value"]
	
	# Aplicar según tipo
	match booster_type:
		"health":
			tracker.apply_health_boost(amount)
			print("  ✅ Boost de salud registrado")
			return true
		
		"power":
			tracker.apply_power_boost(amount)
			print("  ✅ Boost de poder registrado")
			return true
		
		"movement":
			tracker.apply_movement_boost(amount)
			print("  ✅ Boost de movimiento registrado")
			return true
		
		"full_heal":
			var turn_manager = game_manager.get_tree().get_first_node_in_group("turn_manager")
			if not turn_manager or turn_manager.teams.size() == 0:
				return false
			
			var player_team = turn_manager.teams[0]
			var units = player_team.get_living_units()
			
			for unit in units:
				if unit.has_node("HealthComponent"):
					var health_comp = unit.get_node("HealthComponent") as HealthComponent
					var old_hp = health_comp.hp
					health_comp.hp = health_comp.max_hp
					
					# EMITIR SEÑAL PARA QUE HEALTHBAR SE ACTUALICE
					health_comp.healed.emit(health_comp.max_hp - old_hp)
			
			print("  ✅ Curación completa aplicada")
			return true
		
		_:
			push_error("❌ Tipo de booster desconocido: %s" % booster_type)
			return false

func can_apply() -> bool:
	return true
