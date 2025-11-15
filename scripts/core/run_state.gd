extends Node
class_name RunState

var current_level: int = 0
var total_levels: int = 5
var levels_completed: int = 0

var player_team: Team = null
var enemy_team: Team = null

var currency_manager: CurrencyManager = null
var team_stats_tracker: TeamStatsTracker = null
var shop_inventory: ShopInventory = null
var reward_calculator: RewardCalculator = null

func _ready():
	add_to_group("run_state")
	print("RunState inicializado como singleton")

func initialize(p_total_levels: int):
	current_level = 0
	total_levels = p_total_levels
	levels_completed = 0
	print("RunState: Nueva run inicializada - %d niveles" % total_levels)

func reset_for_new_run():
	current_level = 0
	levels_completed = 0
	if currency_manager:
		currency_manager.reset_coins()
	if team_stats_tracker:
		team_stats_tracker.clear()
	if shop_inventory:
		shop_inventory.clear_inventory()
	print("RunState: Reseteado para nueva run")

func advance_level():
	current_level += 1
	print("RunState: Avanzando a nivel %d/%d" % [current_level, total_levels])

func complete_level():
	levels_completed += 1
	print("RunState: Nivel completado (%d/%d)" % [levels_completed, total_levels])

func is_run_complete() -> bool:
	return current_level >= total_levels

func get_level_progress() -> String:
	return "%d/%d" % [current_level, total_levels]

func ensure_managers_exist():
	if currency_manager == null:
		currency_manager = get_tree().get_first_node_in_group("currency_manager")
	
	if team_stats_tracker == null:
		team_stats_tracker = get_tree().get_first_node_in_group("team_stats_tracker")
	
	if shop_inventory == null:
		shop_inventory = get_tree().get_first_node_in_group("shop_inventory")
	
	if reward_calculator == null:
		reward_calculator = get_tree().get_first_node_in_group("reward_calculator")
