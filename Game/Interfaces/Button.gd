extends Button

@onready var tile_map = $tile_map

var ground_layer = 0

var source_id = 0

var bloc_coord = Vector2i(12,9)

var tile_map_pos = Vector2i(0,0)
# Called when the node enters the scene tree for the first time.
func _ready():
	connect("pressed", on_button_press)

func on_button_press():
	print("test")
	bloc_coord = Vector2i(12,9)
	
	

func _input(event):
	if Input.is_action_just_pressed("click"):
		var mouse_pos = get_global_mouse_position()
		
		if (mouse_pos.y <= 512):
		
			tile_map_pos = tile_map.local_to_map(mouse_pos)
			
			if (bloc_coord == Vector2i(99,99)):
				tile_map.erase_cell(ground_layer, tile_map_pos)
			else:
				tile_map.set_cell(ground_layer, tile_map_pos, source_id, bloc_coord)
