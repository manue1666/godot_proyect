extends Camera2D
class_name BattleCamera

@export var drag_button: MouseButton = MOUSE_BUTTON_RIGHT
@export var zoom_step: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 3.0


var dragging := false
var last_mouse_pos := Vector2.ZERO

func _ready():
	zoom = Vector2.ONE
	limit_smoothed = false # Desactiva suavizado de límites
	limit_left = 0
	limit_top = 0
	limit_right = 1280
	limit_bottom = 720

func _input(event):
	# Arrastre con botón derecho
	if event is InputEventMouseButton:
		if event.button_index == drag_button:
			if event.pressed:
				dragging = true
				last_mouse_pos = event.position
			else:
				dragging = false
				
	elif event is InputEventMouseMotion and dragging:
		var delta = event.position - last_mouse_pos
		position -= delta / zoom.x 
		last_mouse_pos = event.position
		_clamp_position()
	
	# Zoom con la rueda usando acciones
	if event.is_action_pressed("mousewheelup"):
		_zoom_at_point(get_viewport().get_mouse_position(), zoom_step)
	elif event.is_action_pressed("mousewheeldown"):
		_zoom_at_point(get_viewport().get_mouse_position(), -zoom_step)

func _zoom_at_point(_point: Vector2, delta: float):
	var old_zoom = zoom.x
	var new_zoom = clamp(old_zoom + delta, min_zoom, max_zoom)
	
	if new_zoom == old_zoom:
		return
	
	# Posición del mouse en el mundo antes del zoom
	var mouse_world_pos_before = get_global_mouse_position()
	
	# Aplicar zoom
	zoom = Vector2(new_zoom, new_zoom)
	
	# Posición del mouse en el mundo después del zoom
	var mouse_world_pos_after = get_global_mouse_position()
	
	# Ajustar posición para mantener el punto bajo el mouse
	position += mouse_world_pos_before - mouse_world_pos_after
	
	_clamp_position()

func _clamp_position():
	# Calcula el tamaño visible de la cámara
	var screen_size = get_viewport_rect().size
	var half = (screen_size / zoom) * 0.5
	var min_pos = Vector2(limit_left, limit_top) + half
	var max_pos = Vector2(limit_right, limit_bottom) - half
	
	# Asegurar que min_pos no sea mayor que max_pos
	if min_pos.x > max_pos.x:
		position.x = (min_pos.x + max_pos.x) / 2.0
	else:
		position.x = clamp(position.x, min_pos.x, max_pos.x)
		
	if min_pos.y > max_pos.y:
		position.y = (min_pos.y + max_pos.y) / 2.0
	else:
		position.y = clamp(position.y, min_pos.y, max_pos.y)
