extends Resource
class_name MovementData

enum MovementType {
	SQUARE,    # Cuadrado completo (ajedrez: rey)
	X,         # Diagonales (ajedrez: alfil)
	DIAMOND,   # Distancia Manhattan 
	CROSS,     # Solo líneas rectas (ajedrez: torre)
	CIRCLE,    # Radio circular
	KNIGHT,    # Patrón de caballo
	LINE       # Línea recta
}

enum MovementRangeType {
	STANDARD,
	FLYING,
	TELEPORT
}

@export var movement_name: String = "Standard"
@export var movement_type: MovementType = MovementType.DIAMOND
@export var range_type: MovementRangeType = MovementRangeType.STANDARD
@export var base_range: int = 2

# Conversión a RangeCalculator.RangeType
func get_range_calculator_type() -> RangeCalculator.RangeType:
	match movement_type:
		MovementType.SQUARE:
			return RangeCalculator.RangeType.SQUARE
		MovementType.X:
			return RangeCalculator.RangeType.X
		MovementType.DIAMOND:
			return RangeCalculator.RangeType.DIAMOND
		MovementType.CROSS:
			return RangeCalculator.RangeType.CROSS
		MovementType.CIRCLE:
			return RangeCalculator.RangeType.CIRCLE
		MovementType.KNIGHT:
			return RangeCalculator.RangeType.KNIGHT
		MovementType.LINE:
			return RangeCalculator.RangeType.LINE
		_:
			return RangeCalculator.RangeType.DIAMOND

func is_valid() -> bool:
	return base_range > 0
