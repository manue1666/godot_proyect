extends Node

class_name UnitStateMachine

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

signal state_changed(old_state: State, new_state: State)

var current_state: State = State.IDLE
var attack_number: int = 0

func change_state(new_state: State):
	if current_state == new_state:
		return
	var old_state = current_state
	current_state = new_state
	state_changed.emit(old_state, new_state)



func is_idle() -> bool:
	return current_state == State.IDLE

func is_selected() -> bool:
	return current_state == State.SELECTED

func is_waiting_move() -> bool:
	return current_state == State.WAITING_MOVE

func is_waiting_attack() -> bool:
	return current_state == State.WAITING_ATTACK

func is_exhausted() -> bool:
	return current_state == State.EXHAUSTED

func is_dead() -> bool:
	return current_state == State.DEAD

func can_act() -> bool:
	return current_state in [State.IDLE, State.SELECTED]

func reset_for_new_turn():
	if current_state != State.DEAD:
		change_state(State.IDLE)
