extends Node2D

@onready var tile_map = $TileMap
@onready var tile_map_no_collision = $TileMapNoCollision

@onready var spawn1 = $"SpawnLocations/0"
@onready var spawn2 = $"SpawnLocations/1"
@onready var btn1 = get_node("Control/CanvasLayer/PanelContainer/MarginContainer/GridContainer/Button")
@onready var btn2 = get_node("Control/CanvasLayer/PanelContainer/MarginContainer/GridContainer/Button2")
@onready var btn3 = get_node("Control/CanvasLayer/PanelContainer/MarginContainer/GridContainer/Button3")
@onready var kill = get_node("Control/CanvasLayer/PanelContainer/MarginContainer/GridContainer/Kill")
@onready var ui = $Control
@onready var playTimer = $PlayTimer
#@onready var items = get_node("/root/Items")
@onready var saw_test = $"Items/Saw"

@export var PlayerScene : PackedScene

var ground_layer = 0

var overlay = 0
var block_active = false

var source_id = 0

var button = false

var bloc_coord = Vector2i(12,9)

var tile_map_pos = Vector2i(0,0)
var x1Min = 1
var x1Max = 30
var yMin = 2
var yMax = 31
var x2Min = x1Min + 31
var x2Max = x1Max + 31
var padding = 8

var start = Vector2i(0,0)
var end = Vector2i(0,0)

var player

var erase_text = Vector2i(18,5)

var counterSwitch = 0
func _ready():
	btn1.connect("pressed", _on_button_pressed)
	btn2.connect("pressed", _on_button_2_pressed)
	btn3.connect("pressed", _on_button_3_pressed)
	kill.connect("pressed", _on_kill_pressed)
	
	saw_test.set_global_position(Vector2i(200,200))
	
	var index = 1
	for i in GameManager.Players:
		var currentPlayer = PlayerScene.instantiate()
		currentPlayer.name = str(GameManager.Players[i].id)
		add_child(currentPlayer)
		for spawn in get_tree().get_nodes_in_group("PlayerSpawnPoint"):
			if spawn.name == str(GameManager.Players[i].index):
				currentPlayer.global_position = spawn.global_position
		index += 1
	pass
	#if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
	if $MultiplayerSynchronizer.get_multiplayer_authority() == GameManager.Players[str(multiplayer.get_unique_id())].index:
		start = startBlockCoords(padding)
		end = finishBlockCoords(start, padding)
		rpc("updateStartEnd", start, end)
		GameManager.Players[str(multiplayer.get_unique_id())].spawn = spawnPos(start)
		initBlockGen(start, end)
		player = get_node(str(multiplayer.get_unique_id()))
		print(player)
	else:
		while start == Vector2i(0,0):
			await get_tree().create_timer(0.001).timeout
		GameManager.Players[str(multiplayer.get_unique_id())].spawn = Vector2i(spawnPos(start).x + 496, spawnPos(start).y)
		initBlockGen(start, end)
		player = get_node(str(multiplayer.get_unique_id()))

func blockGen2x2(ULx,ULy,TMx,TMy):
	tile_map.set_cell(ground_layer, Vector2i(ULx,ULy), source_id, Vector2i(TMx,TMy))
	tile_map.set_cell(ground_layer, Vector2i(ULx+1,ULy), source_id, Vector2i(TMx+2,TMy))
	tile_map.set_cell(ground_layer, Vector2i(ULx,ULy+1), source_id, Vector2i(TMx,TMy+2))
	tile_map.set_cell(ground_layer, Vector2i(ULx+1,ULy+1), source_id, Vector2i(TMx+2,TMy+2))
	
func finishCoords(coord,padding,min_coord,max_coord,uppergap=0):
	var rand1 = randi_range(min_coord,coord-(2+padding+uppergap))
	var rand2 = randi_range(coord+(2+padding+uppergap),max_coord)
	
	if coord >= (min_coord+(2+padding+uppergap)) && coord <= (max_coord-(2+padding+uppergap)):
		if randi_range(0,1):
			return rand1
		else:
			return rand2
	elif coord > max_coord-(2+padding+uppergap):
		return rand1
	else:
		return rand2


func startBlockCoords(padding):
	var startx = randi_range(x1Min,x1Max-1)
	var starty = randi_range(yMin,yMax-1)
	
	return Vector2i(startx,starty)
	
func finishBlockCoords(start_block_coords,padding):
	var endx = randi_range(x1Min,x1Max-1)
	var endy = randi_range(yMin,yMax-1)
	if endx > start_block_coords.x-(padding+2) && endx < start_block_coords.x+(padding+2):
		endy = finishCoords(start_block_coords.y,padding,yMin,yMax-1,2)
		
	return Vector2i(endx,endy)
	
func spawnPos(start_block_coords : Vector2i):
	var start_pos = start_block_coords
	start_pos.y -= 1
	start_pos = tile_map.map_to_local(start_pos)
	start_pos.x += 8
	
	return start_pos
	
func initBlockGen(start_block_coords,end_block_coords):
	blockGen2x2(start_block_coords.x,start_block_coords.y,6,0)
	blockGen2x2(end_block_coords.x,end_block_coords.y,6,8)
	blockGen2x2(start_block_coords.x+31,start_block_coords.y,6,0)
	blockGen2x2(end_block_coords.x+31,end_block_coords.y,6,8)

func _on_button_pressed():
	bloc_coord = Vector2i(12,9)
	
func _on_button_2_pressed():
	bloc_coord = Vector2i(17,9)
	
func _on_button_3_pressed():
	bloc_coord = erase_text
	
func _on_kill_pressed():
	player.kill()
		
@rpc("any_peer", "call_local")			
func switchPos1():
	if $MultiplayerSynchronizer.get_multiplayer_authority() == GameManager.Players[str(multiplayer.get_unique_id())].index:
			GameManager.Players[str(multiplayer.get_unique_id())].spawn = Vector2i(spawnPos(start).x + 496, spawnPos(start).y)
	else:
		while start == Vector2i(0,0):
			await get_tree().create_timer(0.000001).timeout
		GameManager.Players[str(multiplayer.get_unique_id())].spawn = spawnPos(start)

@rpc("any_peer", "call_local")	
func switchPos2():
	if $MultiplayerSynchronizer.get_multiplayer_authority() == GameManager.Players[str(multiplayer.get_unique_id())].index:
			GameManager.Players[str(multiplayer.get_unique_id())].spawn = spawnPos(start)
	else:
		while start == Vector2i(0,0):
			await get_tree().create_timer(0.000001).timeout
		GameManager.Players[str(multiplayer.get_unique_id())].spawn = Vector2i(spawnPos(start).x + 496, spawnPos(start).y)
	
	
	
func _input(event):
	if Input.is_action_pressed("click"):
		var mouse_pos = get_global_mouse_position()
		if (mouse_pos.y <= 512):
			tile_map_pos = tile_map.local_to_map(mouse_pos)
			
			if (bloc_coord == erase_text):
				rpc("rpc_erase", ground_layer, tile_map_pos)
			else:
				rpc("rpc_place", ground_layer, tile_map_pos, source_id, bloc_coord)
				
	if event is InputEventMouseMotion:
		var mouse_pos = get_global_mouse_position()
		if (mouse_pos.y <= 512):
			tile_map_pos = tile_map_no_collision.local_to_map(mouse_pos)
			tile_map_no_collision.clear_layer(overlay)
			tile_map_no_collision.set_cell(overlay, tile_map_pos, source_id, bloc_coord)
			tile_map_no_collision.set_layer_modulate(overlay, Color.WHITE)
			if bloc_coord != erase_text:
				tile_map_no_collision.set_layer_modulate(overlay, Color(Color.WHITE, 0.5))
			
			

@rpc("any_peer", "call_local")
func rpc_erase(layer, pos):
	tile_map.erase_cell(layer, pos)

@rpc("any_peer", "call_local")
func rpc_place(layer, pos, id, coord):
	tile_map.set_cell(layer, pos, id, coord)

func _on_round_timer_timeout():
	rpc("switchPos1")
	print("Construction done Now play !")
	player.kill()
	playTimer.start()
	
func _on_play_timer_timeout():
	print("End of the game go to the scoreboard.")
	
@rpc("any_peer", "call_local")
func updateStartEnd(newStart, newEnd):
	start = newStart
	end = newEnd
