extends "res://Game/Items/items.gd"

func _init():
	scene = load("res://Game/Items/spike.tscn")

func _on_body_entered(body):
	if body.has_method("kill"):
		body.kill()

func _input(event):
	can_place = false
	if Input.is_action_pressed("click"):
		var mouse_pos = get_global_mouse_position()
		var tile_map_pos = level.tile_map.local_to_map(mouse_pos)
		var directions = [Vector2i(-1,0),Vector2i(-1,0),Vector2i(1,0),Vector2i(0,1),Vector2i(0,-1)]
		var surrounding_tiles = []
		for direction in directions:
			surrounding_tiles.append(tile_map_pos+direction)
		if level.tile_map.get_cell_atlas_coords(level.ground_layer,tile_map_pos) == Vector2i(-1,-1):
			for tile in surrounding_tiles:
				if level.tile_map.get_cell_atlas_coords(level.ground_layer,tile) != Vector2i(-1,-1):
					can_place = true
