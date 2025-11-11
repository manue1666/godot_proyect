extends Node2D
class_name InputHandler

var owner_unit: BaseUnit
var tile_size := 32
var ui_handler: UIHandler

func _ready():
	owner_unit = get_parent() as BaseUnit
	if not owner_unit:
		push_error("❌ InputHandler: No encontró BaseUnit padre")
		return
	
	ui_handler = owner_unit.get_node_or_null("UIHandler")
	if not ui_handler:
		push_error("❌ InputHandler: No encontró UIHandler")
		return
	
	# Conectar botones del panel de menú
	if owner_unit.has_node("MenuPanel"):
		var menu_panel = owner_unit.get_node("MenuPanel")
		if menu_panel.has_node("Move"):
			menu_panel.get_node("Move").connect("pressed", Callable(self, "_on_move_button_pressed"))
		if menu_panel.has_node("Atack1"):
			menu_panel.get_node("Atack1").connect("pressed", Callable(self, "_on_attack_one_button_pressed"))
		if menu_panel.has_node("Atack2"):
			menu_panel.get_node("Atack2").connect("pressed", Callable(self, "_on_attack_two_button_pressed"))
	
	print("✅ InputHandler inicializado para %s" % owner_unit.name)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if owner_unit.state_machine.is_waiting_move() or owner_unit.state_machine.is_waiting_attack():
			print("❌ Cancelando acción...")
			owner_unit.state_machine.change_state(UnitStateMachine.State.IDLE)
			if ui_handler:
				ui_handler.clear_highlights()
			return
	
	if not event is InputEventMouseButton or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	
	# No procesar si la unidad no está esperando input
	if not owner_unit.state_machine.is_waiting_move() and not owner_unit.state_machine.is_waiting_attack():
		return
	
	#USAR get_global_mouse_position() en lugar de get_viewport().get_mouse_position()
	var click_pos = get_global_mouse_position()
	var cell_clicked = Vector2i(
		int(click_pos.x / tile_size),
		int(click_pos.y / tile_size)
	)
	
	print("🖱️ Click en píxeles: %v → Celda: %v" % [click_pos, cell_clicked])
	
	if owner_unit.state_machine.is_waiting_move():
		_handle_move_input(cell_clicked)
	elif owner_unit.state_machine.is_waiting_attack():
		_handle_attack_input(cell_clicked)

# ============ MANEJAR MOVIMIENTO ============
func _handle_move_input(cell_clicked: Vector2i):
	if not owner_unit.movement_component:
		push_error("❌ InputHandler: No tiene MovementComponent")
		return
	
	# Verificar que la celda es válida
	var movable_cells = owner_unit.movement_component.get_movable_cells()
	print("📊 Celdas válidas para movimiento: %s" % [movable_cells])
	print("📊 Intentando mover a: %v" % cell_clicked)
	
	if cell_clicked not in movable_cells:
		print("⚠️ Celda %v no está en rango de movimiento" % cell_clicked)
		return
	
	# Ejecutar movimiento
	var did_move = await owner_unit.movement_component.move_to(cell_clicked)
	
	if did_move:
		owner_unit.emit_moved(cell_clicked)
		
		# Actualizar estado
		owner_unit.state_machine.use_move_action()
		ui_handler.clear_highlights()
		owner_unit.state_machine.change_state(UnitStateMachine.State.IDLE)
		
		print("✅ Movimiento completado")
	else:
		print("❌ El movimiento no se ejecutó correctamente")

# ============ MANEJAR ATAQUE ============
func _handle_attack_input(cell_clicked: Vector2i):
	if not owner_unit.attack_component:
		push_error("❌ InputHandler: No tiene AttackComponent")
		return
	
	# Obtener la unidad en esa celda
	var target = owner_unit.get_unit_at_cell(cell_clicked)
	if not target:
		print("⚠️ No hay unidad enemiga en %v" % cell_clicked)
		return
	
	# Obtener número de ataque
	var attack_num = owner_unit.state_machine.attack_number
	
	# Verificar que se puede atacar
	if not owner_unit.attack_component.can_attack_target(target, attack_num - 1):
		print("⚠️ No se puede atacar a %s con ataque %d" % [target.name, attack_num])
		return
	
	# Ejecutar ataque
	var did_attack = owner_unit.attack_component.perform_attack(target, attack_num - 1)
	
	if did_attack:
		owner_unit.emit_attacked(target, attack_num)
		
		# Reproducir animación de ataque
		await owner_unit.play_attack_animation(attack_num)
		
		# Actualizar estado
		owner_unit.state_machine.use_attack_action()
		ui_handler.clear_highlights()
		owner_unit.state_machine.change_state(UnitStateMachine.State.IDLE)
		
		print("✅ Ataque completado")
	else:
		print("❌ El ataque no se ejecutó correctamente")

# ============ BOTONES DE MENÚ ============
func _on_move_button_pressed():
	if not owner_unit.state_machine.can_move():
		print("⚠️ No hay acciones de movimiento disponibles")
		return
	
	ui_handler.hide_menu_panel()
	owner_unit.state_machine.change_state(UnitStateMachine.State.WAITING_MOVE)
	print("🎯 Esperando selección de celda para mover...")

func _on_attack_one_button_pressed():
	if not owner_unit.state_machine.can_attack():
		print("⚠️ No hay acciones de ataque disponibles")
		return
	
	ui_handler.hide_menu_panel()
	owner_unit.state_machine.attack_number = 1
	owner_unit.state_machine.change_state(UnitStateMachine.State.WAITING_ATTACK)
	ui_handler.show_attack_tiles(1)
	print("⚔️ Ataque 1 seleccionado - Esperando objetivo...")

func _on_attack_two_button_pressed():
	if not owner_unit.state_machine.can_attack():
		print("⚠️ No hay acciones de ataque disponibles")
		return
	
	ui_handler.hide_menu_panel()
	owner_unit.state_machine.attack_number = 2
	owner_unit.state_machine.change_state(UnitStateMachine.State.WAITING_ATTACK)
	ui_handler.show_attack_tiles(2)
	print("⚔️ Ataque 2 seleccionado - Esperando objetivo...")
