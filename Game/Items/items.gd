extends Node2D

@onready var scene
@onready var item

var inside = false
var currentPostition

func load_item():
	item = scene.instantiate()
	return item

func set_tile_position(positionParam, item):
	if item == "Saw":
		global_position = Vector2(positionParam.x, positionParam.y)
	else:
		global_position = Vector2(round(positionParam.x / GameManager.TILE_SIZE) * GameManager.TILE_SIZE, round(positionParam.y / GameManager.TILE_SIZE) * GameManager.TILE_SIZE)
	return global_position

func _mouse_enter():
	inside = true

func _mouse_exit():
	inside = false
