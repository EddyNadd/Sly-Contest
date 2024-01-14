extends Node2D

@onready var tile_map = $TileMap
@onready var tile_map_no_collision = $TileMapNoCollision

@onready var spawn1 = $"SpawnLocations/0"
@onready var spawn2 = $"SpawnLocations/1"
@onready var grid = $Grid
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
@onready var switchBtn = $switchPos
@onready var quitBtn = $Quit
@onready var soloSpawn = Vector2i(0,0)
@onready var scene = load("res://Game/Interfaces/ScoreBoard.tscn").instantiate()
@onready var scene2 = load("res://control.tscn").instantiate()
@onready var save_file = SaveFile.game_data
var Items = []
var ItemsToMaybeDelete = []
var side = false

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
	$MusicPlayer.play(GameManager.musicProgress)  
	AudioServer.set_bus_mute((AudioServer.get_bus_index("Music")),save_file.toggledSound) 
	for btn in buttons.get_children():
		btn.connect("pressed", reset_cursor)
		btn.connect("pressed", Callable(self,"_on_" + btn.name.to_lower() + "_pressed"))
		add_child(get_node("Control"))
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
		if $MultiplayerSynchronizer.get_multiplayer_authority() == GameManager.Players[str(multiplayer.get_unique_id())].index:
			side = false
			start = startBlockCoords(padding)
			end = finishBlockCoords(start, padding)
			rpc("updateStartEnd", start, end)
			initBlockGen(start, end)
			player = get_node(str(multiplayer.get_unique_id()))
			print(player)
		else:
			side = true
			while start == Vector2i(0,0):
				await get_tree().create_timer(0.001).timeout
			initBlockGen(start, end)
			player = get_node(str(multiplayer.get_unique_id()))
			
		for player in GameManager.Players:
			GameManager.Players[player].completionPoints = 0
			GameManager.Players[player].validationPoints = 0
			GameManager.Players[player].penaltyPoints = 0
			GameManager.Players[player].points = 0
			
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
		remove_child(get_node('Control'))
		switchBtn.visible = true
		quitBtn.visible = true
		var currentPlayer = PlayerScene.instantiate()
		add_child(currentPlayer)
		for spawn in get_tree().get_nodes_in_group("PlayerSpawnPoint"):
			currentPlayer.global_position = spawn.global_position
		loadLevel()
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

func _process(delta):
	if(GameManager.isSolo):
		$timer.hide()
	else:
		$timer.show()
		$timer.set_text(str(round($ConstructionTimer.get_time_left()))+"s")
		if($ConstructionTimer.get_time_left() == 0):
			$timer.set_text(str(round($PlayTimer.get_time_left()))+"s")

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
	if cursor_item and sprite:
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
				if $MultiplayerSynchronizer.get_multiplayer_authority() == GameManager.Players[str(multiplayer.get_unique_id())].index && mouse_pos.x < 16*31:
					placeBlock(tile_map_pos, mouse_pos)
				elif $MultiplayerSynchronizer.get_multiplayer_authority() != GameManager.Players[str(multiplayer.get_unique_id())].index && mouse_pos.x > 16*31:
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
					if str(cursor_item).contains("Saw"):
						sprite.set_global_position(Vector2i(tile_map_no_collision.local_to_map(mouse_pos).x * GameManager.TILE_SIZE + GameManager.TILE_SIZE/2, tile_map_no_collision.local_to_map(mouse_pos).y * GameManager.TILE_SIZE + GameManager.TILE_SIZE/2))
					else:
						sprite.set_global_position(Vector2i(tile_map_no_collision.local_to_map(mouse_pos).x * GameManager.TILE_SIZE, tile_map_no_collision.local_to_map(mouse_pos).y * GameManager.TILE_SIZE))
					sprite.set_modulate(Color(Color.WHITE,0.5))
				
				
func placeBlock(tile_map_pos, mouse_pos):
	if (mouse_pos.y <= 512 and !GameManager.INDESTRUCTIBLES.has(tile_map.get_cell_atlas_coords(ground_layer,tile_map_pos))):
				
			if cursor_item and cursor_item.can_place:
				rpc("rpc_place_item", cursor_item.get_path(), mouse_pos)
			
			if bloc_coord:
				if (bloc_coord == erase_text):
					rpc("rpc_erase", ground_layer, tile_map_pos)
				else:
					rpc("rpc_place", ground_layer, tile_map_pos, source_id, bloc_coord)

@rpc("any_peer", "call_local")
func rpc_erase(layer, pos):
	tile_map.erase_cell(layer, pos)
	for items in ItemsToMaybeDelete:
		if tile_map.local_to_map(items.position) == pos:
			items.queue_free()
			ItemsToMaybeDelete.erase(items)
			for item in Items:
				if tile_map.local_to_map(item.position) == pos:
					Items.erase(item)


@rpc("any_peer", "call_local")
func rpc_place(layer, pos, id, coord):
	tile_map.set_cell(layer, pos, id, coord)
	
@rpc("any_peer", "call_local")
func rpc_place_item(cursor_item, pos):
	pos = Vector2i(tile_map_no_collision.local_to_map(pos).x * GameManager.TILE_SIZE + GameManager.TILE_SIZE/2, tile_map_no_collision.local_to_map(pos).y * GameManager.TILE_SIZE + GameManager.TILE_SIZE/2)
	var currentItem = {}
	var itemName
	var item = get_node(cursor_item).load_item()
	if str(cursor_item).contains("Saw"):
		currentItem = {
			"name" : "Saw",
			"position" : pos
		}
		itemName = "Saw"
		Items.append(currentItem)
	if str(cursor_item).contains("Spike"):
		currentItem = {
			"name" : "Spike",
			"position" : pos
		}
		Items.append(currentItem)
		itemName = "Spike"
	var positionOfItem = item.set_tile_position(pos, itemName)
	ItemsToMaybeDelete.append(item)
	add_child(item)

func _on_round_timer_timeout():
	if !GameManager.isSolo:
		canBuild = false
		switchPos1()
		print("Construction done Now play !")
		player.kill()
		cursor_item = null
		bloc_coord = null
		GameManager.canFinishLevel = true
		remove_child(get_node('Control'))
		playTimer.start()
		if sprite:
			sprite.set_global_position(Vector2(2000,2000))
		tile_map_no_collision.clear_layer(overlay)
		grid.draw_grid = false
		grid.queue_redraw()
		
	
	
func _on_play_timer_timeout():
	finishGame()
	
@rpc("any_peer", "call_local")
func finishGame():
	print("End of the game go to the scoreboard.")
	if(GameManager.canConfirmLevel):
		for player in GameManager.Players:
			if(GameManager.Players[player].completionPoints > 0):
				GameManager.Players[player].penaltyPoints -= 400
	for player in GameManager.Players:
		GameManager.Players[player].points = GameManager.Players[player].completionPoints + GameManager.Players[player].validationPoints + GameManager.Players[player].penaltyPoints
		print(str(GameManager.Players[player].name)+": "+str(GameManager.Players[player].points)+" (c: "+str(GameManager.Players[player].completionPoints)+", v: "+str(GameManager.Players[player].validationPoints)+", p: "+str(GameManager.Players[player].penaltyPoints)+")")
	saveGameDatas()
	get_tree().root.add_child(scene)
	self.queue_free()
	
	for player in GameManager.Players:
		GameManager.Players[player].spawn = Vector2i(200,1000)
	GameManager.canFinishLevel = false
	GameManager.canConfirmLevel = false
	
@rpc("any_peer", "call_local")
func updateStartEnd(newStart, newEnd):
	start = newStart
	end = newEnd

func saveGameDatas():
	SaveTilemap.save_data(tile_map, Vector2i(onBlockPos(start).x,onBlockPos(start).y), Vector2i(onBlockPos(start).x+496,onBlockPos(start).y), Items)
		
func loadLevel():
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
	soloSpawn = game_data["start"]
	GameManager.soloSpawn2 = game_data["start2"]
	for _i in game_data["items"]:
		var item
		item = get_node(str("Items/"+_i.name)).load_item()
		item.set_tile_position(_i.position, _i.name)
		add_child(item)
		pass


func _on_switch_pos_button_down():
	if soloSpawn == GameManager.soloSpawn:
		GameManager.soloSpawn = GameManager.soloSpawn2
		player.kill()
	else:
		GameManager.soloSpawn = soloSpawn
		player.kill()
	switchBtn.release_focus()


func _on_quit_button_down():
	for scenes in get_tree().root.get_children():
		if scenes != get_tree().current_scene and scenes.name != "GameManager" and scenes.name != "SaveFile" and scenes.name != "SaveTilemap":
			get_tree().root.remove_child(scenes)
	scene2 = load("res://control.tscn").instantiate()
	get_tree().root.add_child(scene2)
	self.queue_free()
	pass # Replace with function body.

func _exit_tree():
	GameManager.musicProgress = $MusicPlayer.get_playback_position()   
