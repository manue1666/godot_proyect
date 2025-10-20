extends ProgressBar
class_name HealthBar

@onready var damage_bar: ProgressBar = $DamageBar
@onready var timer: Timer = $Timer

var owner_unit: BaseUnit
var max_hp: int = 10
var current_hp: int = 10

func _ready():
	owner_unit = get_parent() as BaseUnit
	if not owner_unit:
		push_error("❌ HealthBar: No encontró BaseUnit padre")
		return
	timer.timeout.connect(_on_timer_timeout)
	
	# Conectar señal de daño de la unidad
	owner_unit.receive_dam.connect(_on_unit_damage_received)
	
	update_health_display()
	print("✅ HealthBar inicializado para %s" % owner_unit.name)

func update_health_display():
	max_hp = owner_unit.max_hp
	current_hp = owner_unit.hp
	
	var health_percent = (float(current_hp) / float(max_hp)) * 100
	value = health_percent

func _on_unit_damage_received(_damage: int, _attacker: BaseUnit):
	print("🏥 %s recibió daño. Actualizando HealthBar" % owner_unit.name)
	
	# Actualizar barra verde inmediatamente
	update_health_display()
	
	# Iniciar animación de la barra roja
	timer.start()

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
