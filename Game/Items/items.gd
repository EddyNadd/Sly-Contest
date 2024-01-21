extends Node2D

@onready var scene
@onready var item
@onready var level = get_node("/root/Level")
var inside = false
var can_place = true
var offset = Vector2(0,0)

func load_item():
	item = scene.instantiate()
	return item

func set_tile_position(pos, item):
	global_position = Vector2(round(pos.x / GameManager.TILE_SIZE) * GameManager.TILE_SIZE, round(pos.y / GameManager.TILE_SIZE) * GameManager.TILE_SIZE)
	return global_position

func _mouse_enter():
	inside = true

func _mouse_exit():
	inside = false
