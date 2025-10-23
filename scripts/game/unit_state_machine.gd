extends Node

class_name UnitStateMachine

signal state_changed(old_state, new_state)

enum State {
	IDLE,              # Sin hacer nada
	SELECTED,          # Unidad seleccionada, mostrando menú
	WAITING_MOVE,      # Esperando que el jugador seleccione dónde moverse
	WAITING_ATTACK,    # Esperando que el jugador seleccione a quién atacar
	MOVING,            # Ejecutando movimiento (por si agregas animaciones)
	ATTACKING,         # Ejecutando ataque (por si agregas animaciones)
	EXHAUSTED,         # Ya actuó este turno
	DEAD               # Unidad muerta
}

var current_state := State.IDLE
var attack_number := 1

# Tracking de acciones por turno
var actions_available := {
	"move": false,
	"attack": false
}

var is_stunned: bool = false

func _ready():
	pass

func change_state(new_state: int):
	if new_state == current_state:
		return
	
	var old_state = current_state
	current_state = new_state as State
	state_changed.emit(old_state, new_state)

func reset_actions():
	"""Resetea las acciones disponibles al inicio del turno"""
	actions_available["move"] = true
	actions_available["attack"] = true
	print("  🔄 [%s] Acciones reseteadas: Mover ✅ Atacar ✅" % get_parent().name)

func use_move_action():
	"""Marca que el movimiento fue usado"""
	if actions_available["move"]:
		actions_available["move"] = false
		print("  📍 [%s] Movimiento usado" % get_parent().name)
		return true
	return false

func use_attack_action():
	"""Marca que el ataque fue usado"""
	if actions_available["attack"]:
		actions_available["attack"] = false
		print("  ⚔️ [%s] Ataque usado" % get_parent().name)
		return true
	return false

func has_actions_left() -> bool:
	"""Retorna true si quedan acciones disponibles"""
	return actions_available["move"] or actions_available["attack"]

func can_act() -> bool:
	# Incluir SELECTED
	return not is_stunned and (current_state == State.IDLE or current_state == State.SELECTED) and has_actions_left()

func can_move() -> bool:
	# Incluir SELECTED
	return (current_state == State.IDLE or current_state == State.SELECTED) and actions_available["move"]

func can_attack() -> bool:
	# Incluir SELECTED
	return (current_state == State.IDLE or current_state == State.SELECTED) and actions_available["attack"]

func is_waiting_move() -> bool:
	return current_state == State.WAITING_MOVE

func is_waiting_attack() -> bool:
	return current_state == State.WAITING_ATTACK

func is_exhausted() -> bool:
	return current_state == State.EXHAUSTED

func is_dead() -> bool:
	return current_state == State.DEAD

func stun_unit():
	is_stunned = true
	print("⚡ Unidad aturdida")

func unstun_unit():
	is_stunned = false
	print("✅ Aturdimiento finalizado")
