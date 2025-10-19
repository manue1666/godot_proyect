# test_manual_draw.gd - Temporal en GroundLayer
extends TileMapLayer

func _ready():
	await get_tree().create_timer(3.0).timeout
	
	print("\n🎨 DIBUJANDO TEST MANUAL...")
	
	# Dibujar un cuadrado gigante en el centro
	for y in range(5, 15):
		for x in range(5, 15):
			set_cell(Vector2i(x, y), 0, Vector2i(0, 0))  # Primer tile del atlas
	
	print("  ✅ Dibujado cuadrado 10x10 en (5,5)")
	print("  Celdas totales: %d" % get_used_cells().size())
