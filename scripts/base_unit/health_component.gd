extends Node
class_name HealthComponent

signal died(unit: BaseUnit)
signal damage_taken(damage: int, attacker: BaseUnit)
signal healed(amount: int)

@export var max_hp: int = 10
@export var hp: int = 10

var owner_unit: BaseUnit

func _ready():
	owner_unit = get_parent() as BaseUnit
	if not owner_unit:
		push_error("HealthComponent debe ser hijo de BaseUnit")
		return
	hp = max_hp

func take_damage(damage: int, attacker: BaseUnit):
	hp -= damage
	print("%s recibió %d de daño de %s. HP: %d/%d" % [
		owner_unit.name, damage, attacker.name, hp, max_hp
	])
	damage_taken.emit(damage, attacker)
	
	# Animación de golpe
	if owner_unit.animation_component:
		_play_hit_feedback()
	
	if hp <= 0:
		die()

func heal(amount: int):
	var healed_amount = min(amount, max_hp - hp)
	hp += healed_amount
	print("%s fue curado por %d. HP: %d/%d" % [
		owner_unit.name, healed_amount, hp, max_hp
	])
	healed.emit(healed_amount)

func is_dead() -> bool:
	return hp <= 0

func die():
	if owner_unit.state_machine:
		owner_unit.state_machine.change_state(UnitStateMachine.State.DEAD)
	
	# Esperar a que la escena esté lista
	await get_tree().process_frame
	
	# Reproducir animación si existe
	if owner_unit.animation_component and owner_unit.animation_component.has_animation("dead"):
		owner_unit.animation_component.play_dead()
		var anim_duration = owner_unit.animation_component.get_animation_duration("dead")
		if anim_duration > 0:
			await get_tree().create_timer(anim_duration).timeout
	
	# Emitir signal ANTES de queue_free
	died.emit(owner_unit)
	owner_unit.queue_free()

func _play_hit_feedback():
	if not owner_unit.has_node("AnimatedSprite2D"):
		return
	
	var sprite = owner_unit.get_node("AnimatedSprite2D")
	var original_pos = sprite.position
	
	var damage_tween = create_tween()
	damage_tween.set_parallel(true)
	
	damage_tween.tween_property(sprite, "modulate", Color.RED, 0.08)
	damage_tween.tween_property(sprite, "modulate", Color.WHITE, 0.08).set_delay(0.08)
	
	damage_tween.tween_property(sprite, "position", original_pos + Vector2(2, 0), 0.04)
	damage_tween.tween_property(sprite, "position", original_pos + Vector2(-2, 0), 0.04).set_delay(0.04)
	damage_tween.tween_property(sprite, "position", original_pos, 0.04).set_delay(0.08)

func get_hp_percentage() -> float:
	return float(hp) / float(max_hp)
