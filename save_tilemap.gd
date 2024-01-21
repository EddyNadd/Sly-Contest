extends Node

#Saving and loading levels

var game_data = {}

func save_data(tile_map: TileMap, start: Vector2i, start2: Vector2i, items : Array):
	var tile_data = {}
	for cell in tile_map.get_used_cells(0):
		var atlas = tile_map.get_cell_atlas_coords(0, cell)
		var id = tile_map.get_cell_source_id(0, cell)
		var alternate = tile_map.get_cell_alternative_tile(0, cell)
		tile_data[str(cell)] = [id, atlas, alternate]
	game_data = {
		"tilemap": tile_data,
		"start": start,
		"start2": start2 ,
		"items": items
	}	
	
func load_data(name):
	var file = FileAccess.open("user://levels/" + name + ".SLAY", FileAccess.READ)
	if not file:
		return null
	file = FileAccess.open("user://levels/" + name + ".SLAY", FileAccess.READ)
	var game_data = file.get_var()
	file.close()
	return(game_data)

func write_data(name):
	var dir = DirAccess.open("user://")
	dir.make_dir("levels")
	var file = FileAccess.open("user://levels/" + name + ".SLAY", FileAccess.WRITE)
	file.store_var(game_data)
	file.close()
