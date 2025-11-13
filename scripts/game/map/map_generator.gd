extends Node
class_name MapGenerator

signal map_generated(map_data: MapData)

@export var map_width: int = 20
@export var map_height: int = 10
@export var use_random_seed: bool = true
@export var fixed_seed: int = 0

# Referencias a TileMapLayers (asignar en editor)
@export var ground_layer: TileMapLayer
@export var obstacles_layer: TileMapLayer
@export var decoration_layer: TileMapLayer

# Densidades de generación
@export_range(0.0, 1.0) var obstacle_density: float = 0.15
@export_range(0.0, 1.0) var water_density: float = 0.05
@export_range(0.0, 1.0) var decoration_density: float = 0.2

var current_map: MapData
var noise: FastNoiseLite = FastNoiseLite.new()
var rng := RandomNumberGenerator.new()

func _ready():
	add_to_group("map_generator")
	
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.08
	noise.fractal_octaves = 3
	
	if use_random_seed:
		rng.randomize()
		noise.seed = rng.randi()
	else:
		rng.seed = fixed_seed
		noise.seed = fixed_seed

	print("🗺️  MapGenerator listo (seed: %d)" % noise.seed)

func generate_new_map() -> MapData:
	print("\n🗺️  Generando nuevo mapa %dx%d..." % [map_width, map_height])
	
	current_map = MapData.new(map_width, map_height)
	current_map.seed_value = noise.seed
	
	_generate_ground_layer()
	_generate_obstacles_layer()
	_generate_decoration_layer()
	_define_spawn_zones()
	_apply_to_tilemap()
	
	map_generated.emit(current_map)
	print("✅ Mapa generado (seed: %d)" % current_map.seed_value)
	
	return current_map

func _generate_ground_layer():
	for y in range(map_height):
		for x in range(map_width):
			var noise_value = _get_noise(x, y, 0.1)
			
			if noise_value < 0.3:
				current_map.set_tile(x, y, MapData.TileType.DIRT)
			elif noise_value < 0.7:
				current_map.set_tile(x, y, MapData.TileType.GRASS)
			else:
				current_map.set_tile(x, y, MapData.TileType.STONE)

func _generate_obstacles_layer():
	# Generar parches de agua
	if water_density > 0:
		var num_patches = rng.randi_range(1, 3)
		for i in range(num_patches):
			var center_x = rng.randi_range(3, map_width - 4)
			var center_y = rng.randi_range(2, map_height - 3)
			var radius = rng.randi_range(1, 2)
			
			for dy in range(-radius, radius + 1):
				for dx in range(-radius, radius + 1):
					if dx * dx + dy * dy <= radius * radius:
						var x = center_x + dx
						var y = center_y + dy
						if x >= 0 and x < map_width and y >= 0 and y < map_height:
							current_map.set_tile(x, y, MapData.TileType.WATER)
	
	# Rocas y árboles aleatorios
	for y in range(map_height):
		for x in range(map_width):
			# Evitar zonas de spawn (primeras 4 columnas de cada lado)
			if x < 4 or x >= map_width - 4:
				continue
			
			if rng.randf() < obstacle_density:
				if current_map.is_walkable(x, y):
					var obstacle_type = rng.randi_range(0, 1)
					if obstacle_type == 0:
						current_map.set_tile(x, y, MapData.TileType.ROCK)
					else:
						current_map.set_tile(x, y, MapData.TileType.TREE)

func _generate_decoration_layer():
	for y in range(map_height):
		for x in range(map_width):
			if current_map.is_walkable(x, y) and rng.randf() < decoration_density:
				var deco_type = rng.randi_range(0, 1)
				if deco_type == 0:
					current_map.set_tile(x, y, MapData.TileType.BUSH)
				else:
					current_map.set_tile(x, y, MapData.TileType.FLOWER)

func _define_spawn_zones():
	# Team 1: Izquierda (columnas 0-3)
	current_map.spawn_positions_team1 = _find_spawn_positions(0, 4, 0, map_height)
	
	# Team 2: Derecha (columnas width-4 a width)
	current_map.spawn_positions_team2 = _find_spawn_positions(map_width - 4, map_width, 0, map_height)
	
	print("  Spawn Team 1: %d posiciones" % current_map.spawn_positions_team1.size())
	print("  Spawn Team 2: %d posiciones" % current_map.spawn_positions_team2.size())

func _find_spawn_positions(x_min: int, x_max: int, y_min: int, y_max: int) -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for y in range(y_min, y_max):
		for x in range(x_min, x_max):
			if current_map.is_walkable(x, y):
				positions.append(Vector2i(x, y))
	return positions

func _apply_to_tilemap():
	if not ground_layer or not obstacles_layer or not decoration_layer:
		push_error("❌ TileMapLayers no asignados en MapGenerator")
		return
	
	print("🎨 Aplicando tiles al mapa...")
	# Limpiar capas
	ground_layer.clear()
	obstacles_layer.clear()
	decoration_layer.clear()

	# Forzar visibilidad (por seguridad)
	ground_layer.visible = true
	ground_layer.z_index = -10
	ground_layer.z_as_relative = false
	
	obstacles_layer.visible = true
	obstacles_layer.z_index = -5
	obstacles_layer.z_as_relative = false
	
	decoration_layer.visible = true
	decoration_layer.z_index = -3
	decoration_layer.z_as_relative = false
	
	var tiles_dibujados = 0
	
	for y in range(map_height):
		for x in range(map_width):
			var tile_type = current_map.get_tile(x, y)
			var atlas_coords = _get_atlas_coords(tile_type)
			var cell_pos = Vector2i(x, y)
			
			match tile_type:
				MapData.TileType.GRASS, MapData.TileType.DIRT, MapData.TileType.STONE:
					ground_layer.set_cell(cell_pos, 0, atlas_coords)
					tiles_dibujados += 1
					
				MapData.TileType.WATER, MapData.TileType.ROCK, MapData.TileType.TREE:
					# Grass debajo de obstáculos
					ground_layer.set_cell(cell_pos, 0, Vector2i(1, 0))
					obstacles_layer.set_cell(cell_pos, 0, atlas_coords)
					tiles_dibujados += 2
					
				MapData.TileType.BUSH, MapData.TileType.FLOWER:
					# Grass debajo de decoración
					ground_layer.set_cell(cell_pos, 0, Vector2i(1, 0))
					decoration_layer.set_cell(cell_pos, 0, atlas_coords)
					tiles_dibujados += 2
	
	print("  ✅ Dibujados %d tiles" % tiles_dibujados)

func _get_atlas_coords(tile_type: MapData.TileType) -> Vector2i:
	match tile_type:
		MapData.TileType.GRASS: return Vector2i(1, 0)
		MapData.TileType.DIRT: return Vector2i(2, 0)
		MapData.TileType.STONE: return Vector2i(3, 0)
		MapData.TileType.WATER: return Vector2i(4, 0)
		MapData.TileType.ROCK: return Vector2i(5, 0)
		MapData.TileType.TREE: return Vector2i(6, 0)
		MapData.TileType.BUSH: return Vector2i(7, 0)
		MapData.TileType.FLOWER: return Vector2i(0, 0)
	return Vector2i(0, 0)

func _get_noise(x: float, y: float, _frequency: float = 0.0) -> float:
	if not noise:
		push_error("❌ Noise no inicializado en MapGenerator!")
		return 0.5  # Valor por defecto
	var value = noise.get_noise_2d(x, y)
	return (value + 1.0) / 2.0
