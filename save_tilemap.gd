extends Node

var game_data = {}

func save_data(name: String, tilemap: TileMap, start: Vector2i, end: Vector2i):
	var file = FileAccess.open("user://" + name + ".SLAY", FileAccess.WRITE)
	var tile_data = {}
	for cell in tilemap.get_used_cells(0):
		var atlas = tilemap.get_cell_atlas_coords(0, cell)
		var id = tilemap.get_cell_source_id(0, cell)
		var alternate = tilemap.get_cell_alternative_tile(0, cell)
		tile_data[str(cell)] = [id, atlas, alternate]
	game_data = {
		"tilemap": tile_data,
		"start": start,
		"end": end
	}
	file.store_var(game_data)
	file.close()
	
func load_data(name):
	var file = FileAccess.open("user://" + name + ".SLAY", FileAccess.READ)
	if not file:
		print("Error loading file")
		file.close()
		return null
	file = FileAccess.open("user://" + name + ".SLAY", FileAccess.READ)
	var game_data = file.get_var()
	file.close()
	return(game_data)
