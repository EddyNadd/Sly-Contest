extends "res://Game/Items/items.gd"

enum Direction {
	left,
	right,
	up,
	down
}

var direction = null
var rot_deg = 0

func _init():
	scene = load("res://Game/Items/spike.tscn")

func _on_body_entered(body):
	if body.has_method("kill"):
		body.kill()

func _input(event):
	can_place = false
	direction = null
	if str(level.cursor_item).contains("Spike"):
		if event is InputEventMouseMotion or Input.is_action_pressed("click"):
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
						match tile-tile_map_pos:
							Vector2i(-1,0):
								direction = Direction.left
							Vector2i(1,0):
								direction = Direction.right
							Vector2i(0,1):
								direction = Direction.down
							Vector2i(0,-1):
								direction = Direction.up

func change_rotation(item):
	rot_deg = 0
	offset = Vector2(0,0)
	match direction:
		Direction.left:
			rot_deg = 90
			offset = Vector2(GameManager.TILE_SIZE,0)
		Direction.right:
			rot_deg = -90
			offset = Vector2(0,GameManager.TILE_SIZE)
		Direction.up:
			rot_deg = 180
			offset = Vector2(GameManager.TILE_SIZE,GameManager.TILE_SIZE)
	item.set_global_rotation_degrees(rot_deg)
	item.set_global_position(item.get_global_position()+offset)
	
