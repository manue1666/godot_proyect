extends Control
class_name BattleHUD

# ============ REFERENCIAS A NODOS EXISTENTES ============
@onready var level_label: Label = $LevelPanel/MarginContainer/HBoxContainer/LevelLabel
@onready var turn_label: Label = $LevelPanel/MarginContainer/HBoxContainer/TurnLabel
@onready var end_turn_button: Button = $Turn

@onready var health_boost_label: Label = $BoostsPanel/MarginContainer/VBoxContainer/HealthBoostLabel
@onready var power_boost_label: Label = $BoostsPanel/MarginContainer/VBoxContainer/PowerLabel
@onready var movement_boost_label: Label = $BoostsPanel/MarginContainer/VBoxContainer/MovBoostLabel

# NUEVAS REFERENCIAS A LOS PANELES
@onready var action_panel: Panel = $ActionPanel
@onready var stats_panel: Panel = $StatsPanel

# Botones de acción
var move_button: Button
var attack_one_button: Button
var attack_two_button: Button

# Labels de estadísticas
var unit_name_label: Label
var unit_hp_label: Label
var unit_power_label: Label
var unit_movement_label: Label
var unit_status_label: Label

var team_stats_tracker: TeamStatsTracker
var current_selected_unit: BaseUnit = null

signal end_turn_pressed()

func _ready():
	add_to_group("battle_hud")
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	
	print("\n🎮 === INICIANDO BATTLE_HUD ===")
	
	# OBTENER REFERENCIAS DE ACTIONPANEL
	_setup_action_panel()
	
	# OBTENER REFERENCIAS DE STATSPANEL
	_setup_stats_panel()
	
	# Obtener referencia a TeamStatsTracker
	await get_tree().process_frame
	team_stats_tracker = get_tree().get_first_node_in_group("team_stats_tracker")
	
	if team_stats_tracker:
		print("✅ BattleHUD conectado a TeamStatsTracker")
		update_boosts_display()
	else:
		print("⚠️  TeamStatsTracker no encontrado")
	
	# CONECTAR CON TURN_MANAGER
	var turn_manager = get_tree().get_first_node_in_group("turn_manager")
	if turn_manager and turn_manager.has_signal("unit_selected"):
		turn_manager.unit_selected.connect(_on_unit_selected)
		print("✅ BattleHUD conectado a TurnManager (unit_selected)")
	else:
		print("⚠️  TurnManager no encontrado o sin señal unit_selected")
	
	# Inicialmente ocultos
	hide_action_panel()
	hide_stats_panel()
	
	print("✅ BattleHUD inicializado\n")

# ============ CONFIGURACIÓN DE PANELES ============

func _setup_action_panel():
	if not action_panel:
		push_error("❌ ActionPanel no encontrado en escena")
		return
	
	print("🔧 Configurando ActionPanel...")
	
	# Obtener botones por ruta relativa
	move_button = action_panel.get_node_or_null("Move")
	attack_one_button = action_panel.get_node_or_null("Attack_one")
	attack_two_button = action_panel.get_node_or_null("Attack_two")
	
	if move_button:
		move_button.pressed.connect(_on_move_pressed)
		print("  ✅ MoveButton conectado")
	else:
		print("  ❌ MoveButton no encontrado")
	
	if attack_one_button:
		attack_one_button.pressed.connect(_on_attack_one_pressed)
		print("  ✅ AttackOneButton conectado")
	else:
		print("  ❌ AttackOneButton no encontrado")
	
	if attack_two_button:
		attack_two_button.pressed.connect(_on_attack_two_pressed)
		print("  ✅ AttackTwoButton conectado")
	else:
		print("  ❌ AttackTwoButton no encontrado")

func _setup_stats_panel():
	if not stats_panel:
		push_error("❌ StatsPanel no encontrado en escena")
		return
	
	print("🔧 Configurando StatsPanel...")
	
	# Obtener labels por ruta relativa
	unit_name_label = stats_panel.get_node_or_null("MarginContainer/VBoxContainer/NameLabel")
	unit_hp_label = stats_panel.get_node_or_null("MarginContainer/VBoxContainer/HPLabel")
	unit_power_label = stats_panel.get_node_or_null("MarginContainer/VBoxContainer/PowerLabel")
	unit_movement_label = stats_panel.get_node_or_null("MarginContainer/VBoxContainer/MovLabel")
	unit_status_label = stats_panel.get_node_or_null("MarginContainer/VBoxContainer/StatusLabel")
	
	if unit_name_label:
		print("  ✅ NameLabel encontrado")
	if unit_hp_label:
		print("  ✅ HPLabel encontrado")
	if unit_power_label:
		print("  ✅ PowerLabel encontrado")
	if unit_movement_label:
		print("  ✅ MovementLabel encontrado")
	if unit_status_label:
		print("  ✅ StatusLabel encontrado")

# ============ SELECCIÓN DE UNIDAD ============

# ESTA FUNCIÓN SE LLAMA DESDE TURN_MANAGER
func _on_unit_selected(unit: BaseUnit):
	print("👆 BattleHUD: Unidad seleccionada - %s (Team: %d)" % [unit.name, unit.team_id])
	
	# Solo mostrar si es unidad del jugador (team_id = 0)
	if not unit or unit.team_id != 0:
		print("  → No es unidad del jugador, ocultando paneles")
		hide_action_panel()
		hide_stats_panel()
		current_selected_unit = null
		return
	
	# Mostrar paneles y guardar referencia
	current_selected_unit = unit
	show_action_panel()
	show_stats_panel()
	update_stats_display()
	print("  → Paneles mostrados")

func show_action_panel():
	if action_panel:
		action_panel.visible = true
		print("  📋 ActionPanel VISIBLE")

func hide_action_panel():
	if action_panel:
		action_panel.visible = false
		print("  📋 ActionPanel OCULTO")

func show_stats_panel():
	if stats_panel:
		stats_panel.visible = true
		print("  📊 StatsPanel VISIBLE")

func hide_stats_panel():
	if stats_panel:
		stats_panel.visible = false
		print("  📊 StatsPanel OCULTO")

# ============ ACTUALIZAR ESTADÍSTICAS ============

func update_stats_display():
	if not current_selected_unit:
		return
	
	print("📊 Actualizando stats de %s" % current_selected_unit.name)
	
	# Nombre
	if unit_name_label:
		unit_name_label.text = current_selected_unit.name.to_upper()
	
	# HP
	if unit_hp_label and current_selected_unit.health_component:
		var hp = current_selected_unit.health_component.hp
		var max_hp = current_selected_unit.health_component.max_hp
		unit_hp_label.text = "❤️ HP: %d/%d" % [hp, max_hp]
	
	# Power
	if unit_power_label:
		unit_power_label.text = "⚔️ Power: %d" % current_selected_unit.power
	
	# Movement
	if unit_movement_label and current_selected_unit.movement_component:
		var current_range = current_selected_unit.movement_component.current_range
		unit_movement_label.text = "🚶 Movement: %d" % current_range
	
	# Status
	if unit_status_label and current_selected_unit.status_manager:
		if current_selected_unit.status_manager.has_active_effect():
			var effect_name = AttackData.Effect.keys()[current_selected_unit.status_manager.current_effect]
			var turns_left = current_selected_unit.status_manager.get_remaining_turns()
			unit_status_label.text = "⚠️ %s (%d turns)" % [effect_name, turns_left]
			unit_status_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			unit_status_label.text = "✅ Normal"
			unit_status_label.add_theme_color_override("font_color", Color.GREEN)

# ============ BOTONES DE ACCIÓN ============

func _on_move_pressed():
	print("🖱️ Botón MOVE presionado")
	
	if not current_selected_unit:
		print("  ❌ No hay unidad seleccionada")
		return
	
	if not current_selected_unit.state_machine.can_move():
		print("  ❌ Unidad no puede moverse (acciones gastadas)")
		return
	
	print("  ✅ Iniciando movimiento de %s" % current_selected_unit.name)
	
	# Cambiar estado a WAITING_MOVE
	current_selected_unit.state_machine.change_state(UnitStateMachine.State.WAITING_MOVE)
	
	# Mostrar casillas de movimiento en UIHandler
	if current_selected_unit.ui_handler:
		current_selected_unit.ui_handler.show_movable_tiles()
	
	# Ocultar panel de acciones
	hide_action_panel()

func _on_attack_one_pressed():
	print("🖱️ Botón ATTACK 1 presionado")
	
	if not current_selected_unit:
		print("  ❌ No hay unidad seleccionada")
		return
	
	if not current_selected_unit.state_machine.can_attack():
		print("  ❌ Unidad no puede atacar (acciones gastadas)")
		return
	
	if not current_selected_unit.attack_component:
		print("  ❌ Unidad no tiene AttackComponent")
		return
	
	var attack_data = current_selected_unit.attack_component.get_attack(0)
	if not attack_data:
		print("  ❌ Ataque 1 no disponible")
		return
	
	print("  ✅ Seleccionando Attack 1 de %s" % current_selected_unit.name)
	
	# Cambiar estado a WAITING_ATTACK
	current_selected_unit.state_machine.change_state(UnitStateMachine.State.WAITING_ATTACK)
	current_selected_unit.state_machine.attack_number = 1
	
	# Mostrar casillas de ataque en UIHandler
	if current_selected_unit.ui_handler:
		current_selected_unit.ui_handler.show_attack_tiles(1)
	
	# Ocultar panel de acciones
	hide_action_panel()

func _on_attack_two_pressed():
	print("🖱️ Botón ATTACK 2 presionado")
	
	if not current_selected_unit:
		print("  ❌ No hay unidad seleccionada")
		return
	
	if not current_selected_unit.state_machine.can_attack():
		print("  ❌ Unidad no puede atacar (acciones gastadas)")
		return
	
	if not current_selected_unit.attack_component:
		print("  ❌ Unidad no tiene AttackComponent")
		return
	
	var attack_data = current_selected_unit.attack_component.get_attack(1)
	if not attack_data:
		print("  ❌ Ataque 2 no disponible")
		return
	
	print("  ✅ Seleccionando Attack 2 de %s" % current_selected_unit.name)
	
	# Cambiar estado a WAITING_ATTACK
	current_selected_unit.state_machine.change_state(UnitStateMachine.State.WAITING_ATTACK)
	current_selected_unit.state_machine.attack_number = 2
	
	# Mostrar casillas de ataque en UIHandler
	if current_selected_unit.ui_handler:
		current_selected_unit.ui_handler.show_attack_tiles(2)
	
	# Ocultar panel de acciones
	hide_action_panel()

# ============ BOOSTS ============

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

# ============ ACTUALIZAR CUANDO CAMBIAN STATS ============
# Llamar esto desde donde se tomen daños, curaciones, etc.

func update_unit_hp():
	if current_selected_unit:
		update_stats_display()

func update_unit_status():
	if current_selected_unit:
		update_stats_display()
