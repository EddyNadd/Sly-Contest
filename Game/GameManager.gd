extends Node

var Players = {}
var INDESTRUCTIBLES = []
var canFinishLevel = false
var canConfirmLevel = false
const TILE_SIZE = 16
var isSolo = false
var loadLevel = ""
var isInSave = false
var isInMenu = true
var soloSpawn = Vector2i(0,0)
var soloSpawn2 = Vector2i(0,0)
var lobby
var finished = false

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(4):
		for j in range(3):
			INDESTRUCTIBLES.append(Vector2i(12 + i, j))
			INDESTRUCTIBLES.append(Vector2i(6 + i, j))
			INDESTRUCTIBLES.append(Vector2i(6 + i, 8 + j))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
