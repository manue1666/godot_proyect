extends Resource
class_name MapData

enum TileType {
	GRASS,
	DIRT,
	STONE,
	WATER,
	ROCK,
	TREE,
	BUSH,
	FLOWER
}

@export var width: int = 20
@export var height: int = 10
@export var seed_value: int = 0

# Matriz de tiles [y][x]
var tiles: Array[Array] = []

# Zonas de spawn
var spawn_positions_team1: Array[Vector2i] = []
var spawn_positions_team2: Array[Vector2i] = []

func _init(w: int = 20, h: int = 10):
	width = w
	height = h
	_initialize_tiles()

func _initialize_tiles():
	tiles = []
	for y in range(height):
		var row: Array = []
		for x in range(width):
			row.append(TileType.GRASS)
		tiles.append(row)

func set_tile(x: int, y: int, tile_type: TileType):
	if x >= 0 and x < width and y >= 0 and y < height:
		tiles[y][x] = tile_type

func get_tile(x: int, y: int) -> TileType:
	if x >= 0 and x < width and y >= 0 and y < height:
		return tiles[y][x]
	return TileType.GRASS

func is_walkable(x: int, y: int) -> bool:
	var tile = get_tile(x, y)
	return tile in [TileType.GRASS, TileType.DIRT, TileType.STONE, TileType.BUSH, TileType.FLOWER]

func is_obstacle(x: int, y: int) -> bool:
	var tile = get_tile(x, y)
	return tile in [TileType.WATER, TileType.ROCK, TileType.TREE]
