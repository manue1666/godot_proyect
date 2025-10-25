extends Node
class_name UIHandler

var owner_unit: BaseUnit
var highlights := []
var tile_size := 32

var highlight_scene: PackedScene = preload("res://scenes/interfaz/move_sign.tscn")
var atack_highlight_scene: PackedScene = preload("res://scenes/interfaz/atack_sign.tscn")
var atack_range_highlight_scene: PackedScene = preload("res://scenes/interfaz/atack_range_sign.tscn")

func _ready():
	owner_unit = get_parent() as BaseUnit
	if not owner_unit:
		push_error("❌ UIHandler: No encontró BaseUnit padre")
		return
	
	# ESPERAR un frame para que state_machine esté listo
	await get_tree().process_frame
	
	# Conectar con la máquina de estados
	if owner_unit.state_machine:
		owner_unit.state_machine.state_changed.connect(_on_state_changed)
		print("✅ UIHandler conectado a state_machine de %s" % owner_unit.name)
	else:
		push_error("❌ UIHandler: No encontró UnitStateMachine")
		return
	
	# FORZAR estado inicial
	_on_state_changed(UnitStateMachine.State.IDLE, owner_unit.state_machine.current_state)
	
	print("✅ UIHandler inicializado para %s" % owner_unit.name)

func _on_state_changed(_old_state: int, new_state: int):
	print("🎨 [%s] UIHandler: Estado cambió a %s" % [owner_unit.name, UnitStateMachine.State.keys()[new_state]])
	
	match new_state:
		UnitStateMachine.State.SELECTED:
			print("  → Mostrando menú")
			show_menu_panel()
		
		UnitStateMachine.State.IDLE, UnitStateMachine.State.EXHAUSTED:
			print("  → Ocultando UI")
			hide_menu_panel()
			clear_highlights()
			
		UnitStateMachine.State.WAITING_MOVE:
			print("  → Mostrando casillas de movimiento")
			show_movable_tiles()
		
		UnitStateMachine.State.WAITING_ATTACK:
			print("  → Esperando selección de objetivo")
			pass
		
		UnitStateMachine.State.MOVING:
			if owner_unit.animation_component:
				owner_unit.animation_component.play_move()
		
		UnitStateMachine.State.DEAD:
			hide_menu_panel()
			clear_highlights()

# ============ MENU PANEL ============
func show_menu_panel():
	if owner_unit.has_node("MenuPanel"):
		var menu_panel = owner_unit.get_node("MenuPanel")
		menu_panel.visible = true
		print("  📋 MenuPanel VISIBLE para %s" % owner_unit.name)
	else:
		push_error("❌ UIHandler: No encontró MenuPanel en %s" % owner_unit.name)

func hide_menu_panel():
	if owner_unit.has_node("MenuPanel"):
		owner_unit.get_node("MenuPanel").visible = false

# ============ HIGHLIGHTS ============
func show_movable_tiles():
	clear_highlights()
	if not owner_unit.movement_component:
		return
	
	var cells = owner_unit.movement_component.get_movable_cells()
	for cell in cells:
		var h = highlight_scene.instantiate()
		h.position = Vector2(cell.x, cell.y) * tile_size + Vector2(tile_size * 0.5, tile_size * 0.5)
		owner_unit.get_parent().add_child(h)
		highlights.append(h)
	
	print("📍 Mostradas %d casillas de movimiento para %s" % [cells.size(), owner_unit.name])

func show_attack_tiles(attack_num: int):
	clear_highlights()
	if not owner_unit.attack_component:
		return
	
	var cells = owner_unit.attack_component.get_attackable_cells(attack_num - 1)
	for cell in cells:
		var target = owner_unit.get_unit_at_cell(cell)
		var h
		
		if target and owner_unit.attack_component.can_attack_target(target, attack_num - 1):
			h = atack_highlight_scene.instantiate()
		else:
			h = atack_range_highlight_scene.instantiate()
		
		h.position = Vector2(cell.x, cell.y) * tile_size + Vector2(tile_size * 0.5, tile_size * 0.5)
		owner_unit.get_parent().add_child(h)
		highlights.append(h)
	
	print("⚔️ Mostradas %d casillas de ataque para %s" % [cells.size(), owner_unit.name])

func clear_highlights():
	for h in highlights:
		h.queue_free()
	highlights.clear()
