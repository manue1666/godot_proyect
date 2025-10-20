extends Node
class_name EnemyAI

var turn_manager: TurnManager
var enemy_team: Team

func _ready():
	add_to_group("enemy_ai")
	await get_tree().process_frame
	
	turn_manager = get_tree().get_first_node_in_group("turn_manager")
	if not turn_manager:
		push_error("❌ EnemyAI: No encontró TurnManager")
		return
	
	turn_manager.turn_started.connect(_on_turn_started)
	print("✅ EnemyAI inicializado")

func _on_turn_started(team: Team):
	# Solo actuar si es el turno del equipo enemigo (id = 1)
	if team.team_id != 1:
		return
	
	print("\n🤖 === TURNO DE IA ===")
	enemy_team = team
	
	# ⭐ RESETEAR AQUÍ el equipo enemigo
	print("  🔄 Reseteando estados del equipo enemigo...")
	for unit in enemy_team.get_living_units():
		if unit.state_machine and unit.state_machine.is_exhausted():
			unit.state_machine.change_state(UnitStateMachine.State.IDLE)
	
	# Esperar a que se procese
	await get_tree().process_frame
	
	# Esperar antes de actuar
	await get_tree().create_timer(1.0).timeout
	
	# Procesar cada unidad viva del equipo enemigo
	var living_units = enemy_team.get_living_units()
	for unit in living_units:
		if unit.state_machine.can_act():
			print("  ⚙️ %s puede actuar" % unit.name)
			# ✅ Crear instancia directamente sin guardarla
			await UnitAI.new(unit, turn_manager).take_action()
			await get_tree().create_timer(0.5).timeout
		else:
			print("  ⏸️ %s no puede actuar (estado: %s)" % [unit.name, UnitStateMachine.State.keys()[unit.state_machine.current_state]])
	
	print("🤖 IA completó su turno\n")
	
	# AUTO end turn para IA
	print("⏭️  End turn automático de IA")
	turn_manager.end_turn()
