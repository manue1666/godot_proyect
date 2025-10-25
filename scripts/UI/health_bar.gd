extends ProgressBar
class_name HealthBar

@onready var damage_bar: ProgressBar = $DamageBar
@onready var timer: Timer = $Timer

var owner_unit: BaseUnit
var health_component: HealthComponent
var max_hp: int = 10
var current_hp: int = 10

func _ready():
	owner_unit = get_parent() as BaseUnit
	if not owner_unit:
		push_error("❌ HealthBar: No encontró BaseUnit padre")
		return
	
	#BUSCAR DIRECTAMENTE DEL ÁRBOL
	health_component = owner_unit.get_node_or_null("HealthComponent")
	
	if not health_component:
		push_error("❌ HealthBar: %s no tiene HealthComponent como hijo" % owner_unit.name)
		return
	
	timer.timeout.connect(_on_timer_timeout)
	
	# Conectar señales de HealthComponent directamente
	health_component.damage_taken.connect(_on_unit_damage_received)
	health_component.healed.connect(_on_unit_healed)
	
	update_health_display()
	print("HealthBar inicializado para %s" % owner_unit.name)

func update_health_display():
	# ACCEDER a través de health_component local
	max_hp = health_component.max_hp
	current_hp = health_component.hp
	
	var health_percent = (float(current_hp) / float(max_hp)) * 100
	value = health_percent

func _on_unit_damage_received(_damage: int, _attacker: BaseUnit):
	print("🏥 %s recibió daño. Actualizando HealthBar" % owner_unit.name)
	
	# Actualizar barra verde inmediatamente
	update_health_display()
	
	# Iniciar animación de la barra roja
	timer.start()

func _on_unit_healed(_amount: int):
	print("💚 %s fue curado. Actualizando HealthBar" % owner_unit.name)
	update_health_display()

func _on_timer_timeout():
	# Animar damage_bar hacia el valor de value
	var target_value = value
	var current_value = damage_bar.value
	# Interpolación suave
	var new_value = lerp(current_value, target_value, 0.08)
	damage_bar.value = new_value
	# Parar cuando estén prácticamente iguales
	if abs(new_value - target_value) < 1:
		damage_bar.value = target_value
		timer.stop()
