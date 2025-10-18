extends Node
class_name AnimationComponent

signal animation_finished(anim_name: String)

@export var animated_sprite: AnimatedSprite2D
var owner_unit: BaseUnit

# Animaciones estándar que todas las unidades deben tener
const ANIM_IDLE := "idle"
const ANIM_DEAD := "dead"
const ANIM_ATTACK_ONE := "attack_one"
const ANIM_ATTACK_TWO := "attack_two"
const ANIM_MOVE := "move"  # Futuro

var current_animation := ""
var is_playing := false

func _ready():
	owner_unit = get_parent() as BaseUnit
	if not owner_unit:
		push_error("AnimationComponent debe ser hijo de BaseUnit")
		return
	
	# Buscar AnimatedSprite2D automáticamente
	if not animated_sprite:
		animated_sprite = owner_unit.get_node_or_null("AnimatedSprite2D")
	
	if not animated_sprite:
		push_warning("AnimationComponent no encontró AnimatedSprite2D en %s" % owner_unit.name)
		return
	
	# Conectar señal de animación terminada
	animated_sprite.animation_finished.connect(_on_animation_finished)
	
	# Reproducir idle por defecto
	play_idle()

func play_idle():
	play(ANIM_IDLE, true)

func play_dead():
	play(ANIM_DEAD, false)

func play_attack_one() -> bool:
	return play(ANIM_ATTACK_ONE, false)

func play_attack_two() -> bool:
	return play(ANIM_ATTACK_TWO, false)

func play_move():
	play(ANIM_MOVE, true)

# Función genérica para reproducir animaciones
func play(anim_name: String, loop: bool = false) -> bool:
	if not animated_sprite:
		return false
	
	# Verificar que la animación existe
	if not animated_sprite.sprite_frames.has_animation(anim_name):
		push_warning("Animación '%s' no existe en %s" % [anim_name, owner_unit.name])
		return false
	
	current_animation = anim_name
	is_playing = true
	
	# Configurar loop
	animated_sprite.sprite_frames.set_animation_loop(anim_name, loop)
	
	# Reproducir
	animated_sprite.play(anim_name)
	print("🎬 [%s] Reproduciendo: %s (loop: %s)" % [owner_unit.name, anim_name, loop])
	
	return true

func stop():
	if animated_sprite:
		animated_sprite.stop()
		is_playing = false

func _on_animation_finished():
	is_playing = false
	animation_finished.emit(current_animation)
	print("✅ [%s] Animación terminada: %s" % [owner_unit.name, current_animation])
	
	# Volver a idle después de animaciones no-loop
	if current_animation != ANIM_IDLE and current_animation != ANIM_DEAD:
		play_idle()

# Helper para verificar si una animación existe
func has_animation(anim_name: String) -> bool:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return false
	return animated_sprite.sprite_frames.has_animation(anim_name)

# Helper para obtener duración de animación
func get_animation_duration(anim_name: String) -> float:
	if not has_animation(anim_name):
		return 0.0
	
	var frames = animated_sprite.sprite_frames
	var frame_count = frames.get_frame_count(anim_name)
	var fps = frames.get_animation_speed(anim_name)
	
	return frame_count / fps if fps > 0 else 0.0
