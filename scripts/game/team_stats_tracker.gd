extends Node
class_name TeamStatsTracker

# Guardar modificaciones acumuladas
var health_boost: int = 0
var power_boost: int = 0
var movement_boost: int = 0

# Historial de aplicaciones
var applied_boosters: Array[String] = []

func _ready():
	add_to_group("team_stats_tracker")
	print("📊 TeamStatsTracker inicializado")

# APLICAR BOOSTERS 
func apply_health_boost(amount: int):
	health_boost += amount
	applied_boosters.append("health+%d" % amount)
	print("  💚 Boost de salud acumulado: +%d (total: +%d)" % [amount, health_boost])

func apply_power_boost(amount: int):
	power_boost += amount
	applied_boosters.append("power+%d" % amount)
	print("  ⚔️ Boost de poder acumulado: +%d (total: +%d)" % [amount, power_boost])

func apply_movement_boost(amount: int):
	movement_boost += amount
	applied_boosters.append("movement+%d" % amount)
	print("  🚶 Boost de movimiento acumulado: +%d (total: +%d)" % [amount, movement_boost])

# OBTENER BOOSTS
func get_health_boost() -> int:
	return health_boost

func get_power_boost() -> int:
	return power_boost

func get_movement_boost() -> int:
	return movement_boost

# APLICAR A UNIDADES
func apply_all_boosts_to_team(team: Team):
	print("\n📊 === APLICANDO BOOSTS ACUMULADOS ===")
	
	var living_units = team.get_living_units()
	
	if living_units.is_empty():
		print("  ⚠️  No hay unidades vivas para aplicar boosts")
		return
	
	if health_boost > 0:
		print("  💚 Aplicando +%d HP máximo a todas las unidades" % health_boost)
		for unit in living_units:
			if not is_instance_valid(unit):
				continue
			
			if unit.has_node("HealthComponent"):
				var health_comp = unit.get_node("HealthComponent") as HealthComponent
				health_comp.max_hp += health_boost
				health_comp.hp = health_comp.max_hp  # Full heal al aplicar
	
	if power_boost > 0:
		print("  ⚔️ Aplicando +%d poder a todas las unidades" % power_boost)
		for unit in living_units:
			if not is_instance_valid(unit):
				continue
			# Power se suma directamente
			unit.power += power_boost
	
	if movement_boost > 0:
		print("  🚶 Aplicando +%d movimiento a todas las unidades" % movement_boost)
		for unit in living_units:
			if not is_instance_valid(unit):
				continue
			
			if unit.has_node("MovementComponent"):
				var movement_comp = unit.get_node("MovementComponent") as MovementComponent
				# USAR set_range_boost que calcula desde el original
				movement_comp.set_range_boost(movement_boost)
	
	print("=====================================\n")

func print_status() -> void:
	print("\n📊 === TEAM STATS TRACKER ===")
	print("  Boost de Salud: +%d" % health_boost)
	print("  Boost de Poder: +%d" % power_boost)
	print("  Boost de Movimiento: +%d" % movement_boost)
	print("  Boosters aplicados: %d" % applied_boosters.size())
	for booster in applied_boosters:
		print("    • %s" % booster)
	print("============================\n")

func clear():
	health_boost = 0
	power_boost = 0
	movement_boost = 0
	applied_boosters.clear()
	print("🔄 TeamStatsTracker limpiado")
