extends Node2D

@export var damage_amount: int = 0
@export var duration: float = 1.0
@export var rise_distance: float = 30.0

func _ready():
	if has_node("Label"):
		$Label.text = "-%d" % damage_amount
	
	# Animación: subir y desvanecer
	var popup_tween = create_tween()
	popup_tween.set_parallel(true)
	# Subir
	popup_tween.tween_property(self, "position", position + Vector2(0, -rise_distance), duration)
	# Desvanecer
	popup_tween.tween_property(self, "modulate:a", 0.0, duration)
	# Destruir después
	await popup_tween.finished
	queue_free()
