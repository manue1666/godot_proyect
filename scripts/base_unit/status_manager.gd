extends Node
class_name StatusManager

signal effect_applied(effect: AttackData.Effect, duration: int)
signal effect_expired(effect: AttackData.Effect)

@export var icon_scene: PackedScene = preload("res://scenes/interfaz/status_icon.tscn")

var owner_unit: BaseUnit
var current_effect: AttackData.Effect = AttackData.Effect.NONE
var effect_duration: int = 0
var effect_icon: Node = null
var turn_counter: int = 0

func _ready():
	owner_unit = get_parent() as BaseUnit
	if not owner_unit:
		push_error("StatusManager debe ser hijo de BaseUnit")
		return
	
	# Conectar con el turn_manager para decrementar efectos
	var turn_manager = get_tree().get_first_node_in_group("turn_manager")
	if turn_manager:
		turn_manager.turn_started.connect(_on_turn_started)

func apply_effect(effect: AttackData.Effect, duration: int) -> bool:
	# HEAL y NONE son casos especiales
	if effect == AttackData.Effect.NONE or effect == AttackData.Effect.HEAL:
		return false
	
	# Si ya tiene efecto, rechazar
	if has_active_effect():
		print("❌ %s ya tiene efecto activo: %s" % [owner_unit.name, AttackData.Effect.keys()[current_effect]])
		return false
	
	# Aplicar nuevo efecto
	current_effect = effect
	effect_duration = duration
	turn_counter = 0
	
	print("✅ %s recibió efecto: %s (durará %d turnos)" % [
		owner_unit.name,
		AttackData.Effect.keys()[effect],
		duration
	])
	
	_apply_effect_logic(effect)
	_create_effect_icon()
	effect_applied.emit(effect, duration)
	
	return true

func _apply_effect_logic(effect: AttackData.Effect):
	match effect:
		AttackData.Effect.POISON:
			print("🧪 [POISON] %s será envenenado" % owner_unit.name)
		AttackData.Effect.STUN:
			print("⚡ [STUN] %s está aturdido" % owner_unit.name)
			if owner_unit.state_machine:
				owner_unit.state_machine.stun_unit()
		AttackData.Effect.SLOW:
			print("🐌 [SLOW] %s está ralentizado" % owner_unit.name)
			if owner_unit.movement_component:
				owner_unit.movement_component.apply_slow()

func _create_effect_icon():
	if effect_icon:
		effect_icon.queue_free()
	
	effect_icon = icon_scene.instantiate()
	owner_unit.add_child(effect_icon)
	effect_icon.position = Vector2(0, -40)
	effect_icon.setup(current_effect, effect_duration)
	print("🎯 Icono creado en posición (0, -40)")

func _on_turn_started(team: Team):
	if owner_unit.team != team or not has_active_effect():
		return
	
	turn_counter += 1
	print("📊 %s: efecto %s - turno %d/%d" % [
		owner_unit.name,
		AttackData.Effect.keys()[current_effect],
		turn_counter,
		effect_duration
	])
	
	# Aplicar efecto cada turno
	_tick_effect()
	
	# Verificar si expiró
	if turn_counter >= effect_duration:
		clear_effect()

func _tick_effect():
	match current_effect:
		AttackData.Effect.POISON:
			# Daño por turno
			var poison_damage = 2
			owner_unit.receive_damage(poison_damage, owner_unit)
			print("🧪 %s recibe %d de daño por veneno" % [owner_unit.name, poison_damage])
		AttackData.Effect.SLOW:
			# El slow reduce movimiento, efecto pasivo
			pass
		AttackData.Effect.STUN:
			# STUN ya está siendo manejado por state_machine
			pass

func clear_effect():
	if not has_active_effect():
		return
	
	var expired_effect = current_effect
	print("⏰ Efecto expiró: %s en %s" % [
		AttackData.Effect.keys()[expired_effect],
		owner_unit.name
	])
	
	# Revertir efectos
	match expired_effect:
		AttackData.Effect.STUN:
			if owner_unit.state_machine:
				owner_unit.state_machine.unstun_unit()
		AttackData.Effect.SLOW:
			if owner_unit.movement_component:
				owner_unit.movement_component.remove_slow()
	
	# Limpiar
	current_effect = AttackData.Effect.NONE
	effect_duration = 0
	turn_counter = 0
	
	if effect_icon:
		effect_icon.queue_free()
		effect_icon = null
	
	effect_expired.emit(expired_effect)

# Limpiar todos los efectos
func clear_all_effects():
	if has_active_effect():
		clear_effect()
	print("🧹 Todos los efectos de %s limpiados" % owner_unit.name)

func has_active_effect() -> bool:
	return current_effect != AttackData.Effect.NONE

func get_current_effect() -> AttackData.Effect:
	return current_effect

func get_remaining_turns() -> int:
	if not has_active_effect():
		return 0
	return max(0, effect_duration - turn_counter)
