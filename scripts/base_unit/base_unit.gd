extends Area2D
class_name BaseUnit

signal clicked()
signal moved(unit: BaseUnit, new_position: Vector2i)
signal attacked(attacker: BaseUnit, target: BaseUnit, attack_num: int)
signal died(unit: BaseUnit)
signal receive_dam(damage: int, attacker: BaseUnit)

var tile_size := 32

@export var board_position := Vector2i(0, 0)
@export var power: int = 1

var team: Team = null
var team_id: int = -1

# COMPONENTES - Referencias
var state_machine: UnitStateMachine
var movement_component: MovementComponent
var attack_component: AttackComponent
var animation_component: AnimationComponent
var health_component: HealthComponent
var status_manager: StatusManager
var ui_handler: UIHandler
var input_handler: InputHandler

func _ready():
	add_to_group("units")
	
	# OBTENER COMPONENTES
	state_machine = get_node_or_null("UnitStateMachine")
	if not state_machine:
		push_error("❌ BaseUnit: No encontró UnitStateMachine como hijo")
		return
	
	movement_component = get_node_or_null("MovementComponent")
	attack_component = get_node_or_null("AttackComponent")
	animation_component = get_node_or_null("AnimationComponent")
	health_component = get_node_or_null("HealthComponent")
	status_manager = get_node_or_null("StatusManager")
	ui_handler = get_node_or_null("UIHandler")
	input_handler = get_node_or_null("InputHandler")
	
	# Conectar señales de componentes
	if health_component:
		health_component.died.connect(func(unit): died.emit(unit))
		health_component.damage_taken.connect(func(dmg, attacker): receive_dam.emit(dmg, attacker))
	
	update_visual_position()
	connect("input_event", Callable(self, "_on_input_event"))
	
	print("✅ BaseUnit %s inicializado correctamente" % name)

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("🖱️ Click detectado en: %s" % name)
		clicked.emit()

func select_unit():
	if state_machine.can_act():
		state_machine.change_state(UnitStateMachine.State.SELECTED)

func deselect_unit():
	if not state_machine.is_exhausted():
		state_machine.change_state(UnitStateMachine.State.IDLE)
	if ui_handler:
		ui_handler.clear_highlights()

func play_attack_animation(attack_num: int):
	if not animation_component:
		return
	
	if attack_num == 1:
		await animation_component.play_attack_one()
	elif attack_num == 2:
		await animation_component.play_attack_two()

func receive_damage(damage: int, attacker: BaseUnit):
	if health_component:
		health_component.take_damage(damage, attacker)
	spawn_damage_popup(damage)

func update_visual_position():
	position = Vector2(board_position.x, board_position.y) * tile_size + Vector2(tile_size * 0.5, tile_size * 0.5)

func spawn_damage_popup(damage: int):
	var popup = preload("res://scenes/interfaz/damage_popup.tscn").instantiate()
	popup.damage_amount = damage
	popup.position = position + Vector2(0, -tile_size * 0.5)
	get_parent().add_child(popup)

func get_unit_at_cell(cell: Vector2i) -> BaseUnit:
	var units = get_tree().get_nodes_in_group("units")
	for unit in units:
		if unit is BaseUnit and unit.board_position == cell:
			return unit
	return null

func emit_moved(new_position: Vector2i):
	print("📍 Señal 'moved' emitida: %s → %v" % [name, new_position])
	moved.emit(self, new_position)

func emit_attacked(target: BaseUnit, attack_num: int):
	print("⚔️ Señal 'attacked' emitida: %s atacó a %s con ataque %d" % [name, target.name, attack_num])
	attacked.emit(self, target, attack_num)
