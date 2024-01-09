extends Node2D

@onready var tile_map = $TileMap
@onready var tile_map_no_collision = $TileMapNoCollision

@onready var spawn1 = $"SpawnLocations/0"
@onready var spawn2 = $"SpawnLocations/1"
@onready var buttons = get_node("Control/CanvasLayer/PanelContainer/MarginContainer/GridContainer")
@onready var btn1 = buttons.get_node("Button")
@onready var btn2 = buttons.get_node("Button2")
@onready var erase = buttons.get_node("Erase")
@onready var kill = buttons.get_node("Kill")
@onready var saw = buttons.get_node("Saw")
@onready var spike = buttons.get_node("Spike")
@onready var ui = $Control
@onready var playTimer = $PlayTimer
@onready var saveName = $nameOfSave

@export var PlayerScene : PackedScene

var cursor_item
var sprite

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

var canBuild = true

func _ready():
	for btn in buttons.get_children():
		btn.connect("pressed", reset_cursor)
		btn.connect("pressed", Callable(self,"_on_" + btn.name.to_lower() + "_pressed"))
	
	if GameManager.isSolo == false:
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
			initBlockGen(start, end)
			player = get_node(str(multiplayer.get_unique_id()))
			print(player)
		else:
			while start == Vector2i(0,0):
				await get_tree().create_timer(0.001).timeout
			initBlockGen(start, end)
			player = get_node(str(multiplayer.get_unique_id()))
			
		if $MultiplayerSynchronizer.get_multiplayer_authority() == GameManager.Players[str(multiplayer.get_unique_id())].index:
			for player in GameManager.Players:
				if(GameManager.Players[str(multiplayer.get_unique_id())] == GameManager.Players[player]):
					GameManager.Players[player].spawn = onBlockPos(start)
					GameManager.Players[player].end = onBlockPos(end)
				else:
					GameManager.Players[player].spawn = Vector2i(onBlockPos(start).x + 496, onBlockPos(start).y)
					GameManager.Players[player].end = Vector2i(onBlockPos(end).x + 496, onBlockPos(end).y)
		else:
			for player in GameManager.Players:
				if(GameManager.Players[str(multiplayer.get_unique_id())] == GameManager.Players[player]):
					GameManager.Players[player].spawn = Vector2i(onBlockPos(start).x + 496, onBlockPos(start).y)
					GameManager.Players[player].end = Vector2i(onBlockPos(end).x + 496, onBlockPos(end).y)
				else:
					GameManager.Players[player].spawn = onBlockPos(start)
					GameManager.Players[player].end = onBlockPos(end)
	else:
		var currentPlayer = PlayerScene.instantiate()
		add_child(currentPlayer)
		for spawn in get_tree().get_nodes_in_group("PlayerSpawnPoint"):
			currentPlayer.global_position = spawn.global_position
		_on_load_button_down()
		player = currentPlayer
		
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
	
func onBlockPos(block_coords : Vector2i):
	var on_pos = block_coords
	on_pos.y -= 1
	on_pos = tile_map.map_to_local(on_pos)
	on_pos.x += 8
	
	return on_pos
	
func initBlockGen(start_block_coords,end_block_coords):
	blockGen2x2(start_block_coords.x,start_block_coords.y,6,0)
	blockGen2x2(end_block_coords.x,end_block_coords.y,6,8)
	blockGen2x2(start_block_coords.x+31,start_block_coords.y,6,0)
	blockGen2x2(end_block_coords.x+31,end_block_coords.y,6,8)
	
func reset_cursor():
	if cursor_item:
		sprite.set_global_position(Vector2(2000,2000))
	tile_map_no_collision.clear_layer(overlay)
	cursor_item = null
	bloc_coord = null

func _on_button_pressed():
	bloc_coord = Vector2i(12,9)
	
func _on_button2_pressed():
	bloc_coord = Vector2i(17,9)
	
func _on_erase_pressed():
	bloc_coord = erase_text
	
func _on_kill_pressed():
	player.kill()
	
func _on_saw_pressed():
	cursor_item = get_node("Items/Saw")
	
func _on_spike_pressed():
	cursor_item = get_node("Items/Spike")
		
@rpc("any_peer", "call_local")			
func switchPos1():
	if !GameManager.isSolo:
		var tempSpawn = GameManager.Players[str(multiplayer.get_unique_id())].spawn
		for player in GameManager.Players:
			if(GameManager.Players[str(multiplayer.get_unique_id())] != GameManager.Players[player]):
				GameManager.Players[str(multiplayer.get_unique_id())].spawn = GameManager.Players[player].spawn
				GameManager.Players[player].spawn = tempSpawn
	#	if $MultiplayerSynchronizer.get_multiplayer_authority() == GameManager.Players[str(multiplayer.get_unique_id())].index:
	#			GameManager.Players[str(multiplayer.get_unique_id())].spawn = Vector2i(onBlockPos(start).x + 496, onBlockPos(start).y)
	#	else:
	#		while start == Vector2i(0,0):
	#			await get_tree().create_timer(0.000001).timeout
	#		GameManager.Players[str(multiplayer.get_unique_id())].spawn = onBlockPos(start)

@rpc("any_peer", "call_local")	
func switchPos2():
	if !GameManager.isSolo:
		if $MultiplayerSynchronizer.get_multiplayer_authority() == GameManager.Players[str(multiplayer.get_unique_id())].index:
				GameManager.Players[str(multiplayer.get_unique_id())].spawn = onBlockPos(start)
		else:
			while start == Vector2i(0,0):
				await get_tree().create_timer(0.000001).timeout
			GameManager.Players[str(multiplayer.get_unique_id())].spawn = Vector2i(onBlockPos(start).x + 496, onBlockPos(start).y)
	
func _input(event):
	if GameManager.isSolo == false:
		if Input.is_action_pressed("click"):			
			var mouse_pos = get_global_mouse_position()
			tile_map_pos = tile_map.local_to_map(mouse_pos)
			if canBuild:
				if $MultiplayerSynchronizer.get_multiplayer_authority() == GameManager.Players[str(multiplayer.get_unique_id())].index && tile_map_pos.x < 31:
					placeBlock(tile_map_pos, mouse_pos)
				elif $MultiplayerSynchronizer.get_multiplayer_authority() != GameManager.Players[str(multiplayer.get_unique_id())].index && tile_map_pos.x > 31:
					placeBlock(tile_map_pos, mouse_pos)
				
		if event is InputEventMouseMotion:
			var mouse_pos = get_global_mouse_position()
			if (mouse_pos.y <= 512):
				if bloc_coord:
					tile_map_pos = tile_map_no_collision.local_to_map(mouse_pos)
					tile_map_no_collision.clear_layer(overlay)
					tile_map_no_collision.set_cell(overlay, tile_map_pos, source_id, bloc_coord)
					tile_map_no_collision.set_layer_modulate(overlay, Color.WHITE)
					if bloc_coord != erase_text:
						tile_map_no_collision.set_layer_modulate(overlay, Color(Color.WHITE, 0.5))
						
				if cursor_item:
					sprite = cursor_item.get_node("Sprite")
					sprite.set_global_position(Vector2(2000,2000))
					sprite.set_global_position(Vector2(round(mouse_pos.x / GameManager.TILE_SIZE) * GameManager.TILE_SIZE, round(mouse_pos.y / GameManager.TILE_SIZE) * GameManager.TILE_SIZE))
					sprite.set_modulate(Color(Color.WHITE,0.5))
				
				
func placeBlock(tile_map_pos, mouse_pos):
	if (mouse_pos.y <= 512 and !GameManager.INDESTRUCTIBLES.has(tile_map.get_cell_atlas_coords(ground_layer,tile_map_pos))):
				
			if cursor_item:
				var item = cursor_item.load_item()
				item.set_tile_position(mouse_pos)
				add_child(item)
			
			if bloc_coord:
				if (bloc_coord == erase_text):
					rpc("rpc_erase", ground_layer, tile_map_pos)
				else:
					rpc("rpc_place", ground_layer, tile_map_pos, source_id, bloc_coord)

@rpc("any_peer", "call_local")
func rpc_erase(layer, pos):
	tile_map.erase_cell(layer, pos)

@rpc("any_peer", "call_local")
func rpc_place(layer, pos, id, coord):
	tile_map.set_cell(layer, pos, id, coord)

func _on_round_timer_timeout():
	if !GameManager.isSolo:
		canBuild = false
		switchPos1()
		print("Construction done Now play !")
		player.kill()
		GameManager.canConfirmLevel = true
		playTimer.start()
	
func _on_play_timer_timeout():
	print("End of the game go to the scoreboard.")
	
@rpc("any_peer", "call_local")
func updateStartEnd(newStart, newEnd):
	start = newStart
	end = newEnd

func _on_save_button_down():
	if saveName.text != "":
		SaveTilemap.save_data(saveName.text, tile_map, Vector2i(onBlockPos(start).x,onBlockPos(start).y), Vector2i(onBlockPos(start).x+496,onBlockPos(start).y))

func _on_load_button_down():
	for cell in tile_map.get_used_cells(0):
		tile_map.set_cell(0, cell, -1)
	var game_data = SaveTilemap.load_data(GameManager.loadLevel)
	for cell_str in game_data["tilemap"].keys():
		var components = cell_str.split(",")
		var x = int(components[0])
		var y = int(components[1])
		var id = game_data["tilemap"][cell_str][0]
		var atlas = game_data["tilemap"][cell_str][1]
		var alternate = game_data["tilemap"][cell_str][2]
		tile_map.set_cell(0, Vector2i(x, y), id, atlas, alternate)
	print(game_data["start"])
	GameManager.soloSpawn = game_data["start"]
