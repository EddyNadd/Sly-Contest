extends Node2D

@onready var scene
@onready var item

var inside = false

func load_item():
	item = scene.instantiate()
	return item

func set_tile_position(position):
	global_position = Vector2(round(position.x / GameManager.TILE_SIZE) * GameManager.TILE_SIZE, round(position.y / GameManager.TILE_SIZE) * GameManager.TILE_SIZE)

func _mouse_enter():
	inside = true

func _mouse_exit():
	inside = false

func _input(event):
	var bloc_coord = get_node("/root/Level").bloc_coord
	var erase_text = get_node("/root/Level").erase_text
	
	if Input.is_action_pressed("click") and inside:
		if (bloc_coord == erase_text):
			queue_free()
