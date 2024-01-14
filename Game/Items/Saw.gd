extends "res://Game/Items/items.gd"

func _init():
	scene = load("res://Game/Items/saw.tscn")

func _ready():
	get_node("Sprite").play("on")
	
func set_tile_position(positionParam, item):
	global_position = Vector2(positionParam.x, positionParam.y)
	return global_position

func _on_body_entered(body):
	if body.has_method("kill"):
		body.kill()
