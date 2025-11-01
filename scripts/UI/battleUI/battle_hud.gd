extends Control
class_name BattleHUD

# ============ REFERENCIAS A NODOS EXISTENTES ============
@onready var level_label: Label = $LevelPanel/MarginContainer/HBoxContainer/LevelLabel
@onready var turn_label: Label = $LevelPanel/MarginContainer/HBoxContainer/TurnLabel
@onready var end_turn_button: Button = $Turn

@onready var health_boost_label: Label = $BoostsPanel/MarginContainer/VBoxContainer/HealthBoostLabel
@onready var power_boost_label: Label = $BoostsPanel/MarginContainer/VBoxContainer/PowerLabel
@onready var movement_boost_label: Label = $BoostsPanel/MarginContainer/VBoxContainer/MovBoostLabel

@onready var action_panel: ActionPanel = $ActionPanel
@onready var stats_panel: StatsPanel = $StatsPanel

var team_stats_tracker: TeamStatsTracker
var current_selected_unit: BaseUnit = null

signal end_turn_pressed()

func _ready():
	add_to_group("battle_hud")
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	
	print("\n🎮 === INICIANDO BATTLE_HUD ===")
	
	# Conectar señales de paneles
	action_panel.move_pressed.connect(_on_move_pressed)
	action_panel.attack_one_pressed.connect(_on_attack_one_pressed)
	action_panel.attack_two_pressed.connect(_on_attack_two_pressed)
	
	await get_tree().process_frame
	team_stats_tracker = get_tree().get_first_node_in_group("team_stats_tracker")
	
	if team_stats_tracker:
		print("✅ BattleHUD conectado a TeamStatsTracker")
		update_boosts_display()
	
	var turn_manager = get_tree().get_first_node_in_group("turn_manager")
	if turn_manager and turn_manager.has_signal("unit_selected"):
		turn_manager.unit_selected.connect(_on_unit_selected)
		print("✅ BattleHUD conectado a TurnManager")
	
	action_panel.visible = false
	stats_panel.visible = false
	
	print("✅ BattleHUD inicializado\n")

func _on_unit_selected(unit: BaseUnit):
	print("👆 BattleHUD: Unidad seleccionada - %s (Team: %d)" % [unit.name, unit.team_id])
	
	if not unit:
		action_panel.visible = false
		stats_panel.visible = false
		current_selected_unit = null
		return
	
	current_selected_unit = unit
	stats_panel.visible = true
	stats_panel.update_stats(unit)
	stats_panel.update_attacks(unit)
	
	# Solo mostrar ActionPanel si es aliada
	if unit.team_id == 0:
		action_panel.visible = true
		action_panel.update_attack_buttons(unit)
	else:
		action_panel.visible = false

func _on_move_pressed():
	print("🖱️ Botón MOVE presionado")
	if not current_selected_unit or not current_selected_unit.state_machine.can_move():
		return
	
	current_selected_unit.state_machine.change_state(UnitStateMachine.State.WAITING_MOVE)
	if current_selected_unit.ui_handler:
		current_selected_unit.ui_handler.show_movable_tiles()
	action_panel.visible = false

func _on_attack_one_pressed():
	_handle_attack(1)

func _on_attack_two_pressed():
	_handle_attack(2)

func _handle_attack(attack_num: int):
	print("🖱️ Botón ATTACK %d presionado" % attack_num)
	if not current_selected_unit or not current_selected_unit.state_machine.can_attack():
		return
	
	if not current_selected_unit.attack_component.get_attack(attack_num - 1):
		return
	
	current_selected_unit.state_machine.change_state(UnitStateMachine.State.WAITING_ATTACK)
	current_selected_unit.state_machine.attack_number = attack_num
	if current_selected_unit.ui_handler:
		current_selected_unit.ui_handler.show_attack_tiles(attack_num)
	action_panel.visible = false

func update_level(current: int, total: int):
	level_label.text = "Level %s/%s" % [current, total]

func update_turn(team_name: String):
	turn_label.text = "Turn: %s" % team_name

func update_boosts_display():
	if not team_stats_tracker:
		return
	health_boost_label.text = "💚 Health Boost: +%d" % team_stats_tracker.get_health_boost()
	power_boost_label.text = "⚔️ Power Boost: +%d" % team_stats_tracker.get_power_boost()
	movement_boost_label.text = "🚶 Movement Boost: +%d" % team_stats_tracker.get_movement_boost()

func _on_end_turn_pressed():
	end_turn_pressed.emit()

func update_unit_hp():
	if current_selected_unit:
		stats_panel.update_stats(current_selected_unit)

func update_unit_status():
	if current_selected_unit:
		stats_panel.update_stats(current_selected_unit)
