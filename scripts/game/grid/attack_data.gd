extends Resource
class_name AttackData

enum RangeType {
	SQUARE,    # Cuadrado completo (ajedrez: rey)
	X,         # Forma de X (diagonales - ajedrez: alfil)
	DIAMOND,   # Distancia Manhattan 
	CROSS,     # Solo líneas rectas (ajedrez: torre)
	LINE,      # Línea recta en una dirección
	CIRCLE,    # Radio circular (más realista)
	KNIGHT     # Patrón de caballo de ajedrez (útil para unidades especiales)
}

enum AttackType {
	PHYSICAL,  # Ataque cuerpo a cuerpo
	RANGED,    # Ataque a distancia
	AREA,      # Ataque en área (daña múltiples objetivos)
}

enum Effect {
	NONE,
	POISON,    # Daño con el tiempo
	STUN,      # Pierde siguiente turno
	HEAL,      # Cura en lugar de dañar
	SLOW,      # Reduce movimiento
}

@export var attack_name: String = "Attack"
@export var damage: int = 5
@export var range: int = 1
@export var attack_type: AttackType = AttackType.PHYSICAL
@export var range_type: RangeType = RangeType.DIAMOND
@export var effect: Effect = Effect.NONE
@export var effect_duration: int = 0  # Turnos que dura el efecto

# Validación
func is_valid() -> bool:
	return damage > 0 and range > 0
