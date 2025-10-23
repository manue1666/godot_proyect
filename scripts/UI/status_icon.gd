extends Control

var texture_rect: TextureRect
var label: Label
var effect: AttackData.Effect
var remaining_turns: int

func _ready():
	# Asegurar que los nodos existan
	if has_node("TextureRect"):
		texture_rect = $TextureRect
	else:
		push_error("❌ status_icon no tiene nodo TextureRect")
		return
	
	if has_node("Label"):
		label = $Label
	else:
		push_error("❌ status_icon no tiene nodo Label")
		return
	
func setup(new_effect: AttackData.Effect, duration: int):
	self.effect = new_effect
	self.remaining_turns = duration
	
	print("🎨 Configurando icono para efecto: %s (duración: %d)" % [
		AttackData.Effect.keys()[effect],
		duration
	])
	
	# Cargar icono según efecto
	if texture_rect:  # Verificar que exista
		match self.effect:
			AttackData.Effect.POISON:
				texture_rect.texture = preload("res://sprites/UI/poison_icon.png")
				print("✅ Icono POISON cargado")
			AttackData.Effect.STUN:
				texture_rect.texture = preload("res://sprites/UI/stun_icon.png")
				print("✅ Icono STUN cargado")
			AttackData.Effect.SLOW:
				texture_rect.texture = preload("res://sprites/UI/slow_icon.png")
				print("✅ Icono SLOW cargado")
			_:
				print("❌ Efecto desconocido: %s" % effect)
	
	if label:
		label.text = str(remaining_turns)
		print("✅ Label actualizado: %d" % remaining_turns)

func _on_turns_changed(new_duration: int):
	remaining_turns = new_duration
	if label:
		label.text = str(remaining_turns)
