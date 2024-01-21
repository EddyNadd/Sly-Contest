extends Node

#Global variables
var Players = {}
var indestructibles = []
var can_finish_level = false
var can_confirm_level = false
const TILE_SIZE = 16
var music_progress = 0.0
var is_solo = false
var load_level = ""
var is_in_save = false
var is_in_menu = true
var server_launch_on = false
var solo_spawn = Vector2i(0,0)
var solo_spawn2 = Vector2i(0,0)
var lobby
var finished = false

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(4):
		for j in range(3):
			indestructibles.append(Vector2i(12 + i, j))
			indestructibles.append(Vector2i(6 + i, j))
			indestructibles.append(Vector2i(6 + i, 8 + j))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
