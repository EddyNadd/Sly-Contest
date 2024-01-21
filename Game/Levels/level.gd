extends Node2D

# External node variables
@onready var tile_map = $TileMap
@onready var tile_map_no_collision = $TileMapNoCollision
@onready var spawn1 = $"SpawnLocations/0"
@onready var spawn2 = $"SpawnLocations/1"
@onready var grid = $Grid
@onready var buttons = get_node("Control/CanvasLayer/PanelContainer/MarginContainer/GridContainer")
@onready var ui = $Control
@onready var play_timer = $PlayTimer
@onready var switch_btn = $switchPos
@onready var quit_btn = $Quit
@onready var scene = load("res://Game/Interfaces/ScoreBoard.tscn").instantiate()
@onready var scene2 = load("res://control.tscn").instantiate()

@onready var solo_spawn = Vector2i(0,0)
@onready var save_file = SaveFile.game_data

var items = [] # dictionary values of items for level saves
var items_to_maybe_delete = [] # instanced items

@export var player_scene = preload("res://Game/Characters/player.tscn")

var cursor_item # current selected item
var sprite # sprite of selcted item

# Tile map info
var ground_layer = 0
var source_id = 0

var bloc_coord = Vector2i(12,9) # default selected tile (gold block)

var tile_map_pos = Vector2i(0,0)

var x1_min = 1
var x1_max = 30
var y_min = 2
var y_max = 31
var x2_min = x1_min + 31
var x2_max = x1_max + 31
var padding = 8

var start = Vector2i(0,0)
var end = Vector2i(0,0)

var player

var erase_texture = Vector2i(18,5)

var can_build = false

func _ready():
	for btn in buttons.get_children():
		btn.connect("pressed", reset_cursor)
		btn.connect("pressed", Callable(self,"_on_" + btn.name.to_lower() + "_pressed"))
		add_child(get_node("Control"))
	if GameManager.is_solo == false:
		var index = 1
		for i in GameManager.players:
			var current_player = player_scene.instantiate()
			current_player.name = str(GameManager.players[i].id)
			add_child(current_player)
			for spawn in get_tree().get_nodes_in_group("PlayerSpawnPoint"):
				if spawn.name == str(GameManager.players[i].index):
					current_player.global_position = spawn.global_position
			index += 1
		pass
		if $MultiplayerSynchronizer.get_multiplayer_authority() == GameManager.players[str(multiplayer.get_unique_id())].index:
			start = startBlockCoords(padding)
			end = finishBlockCoords(start, padding)
			rpc("updateStartEnd", start, end)
			initBlockGen(start, end)
			player = get_node(str(multiplayer.get_unique_id()))
		else:
			while start == Vector2i(0,0):
				await get_tree().create_timer(0.001).timeout
			initBlockGen(start, end)
			player = get_node(str(multiplayer.get_unique_id()))
			
		for player in GameManager.players:
			GameManager.players[player].completionPoints = 0
			GameManager.players[player].validationPoints = 0
			GameManager.players[player].penaltyPoints = 0
			GameManager.players[player].points = 0
			
		if $MultiplayerSynchronizer.get_multiplayer_authority() == GameManager.players[str(multiplayer.get_unique_id())].index:
			for player in GameManager.players:
				if(GameManager.players[str(multiplayer.get_unique_id())] == GameManager.players[player]):
					GameManager.players[player].spawn = onBlockPos(start)
					GameManager.players[player].end = onBlockPos(end)
				else:
					GameManager.players[player].spawn = Vector2i(onBlockPos(start).x + 496, onBlockPos(start).y)
					GameManager.players[player].end = Vector2i(onBlockPos(end).x + 496, onBlockPos(end).y)
		else:
			for player in GameManager.players:
				if(GameManager.players[str(multiplayer.get_unique_id())] == GameManager.players[player]):
					GameManager.players[player].spawn = Vector2i(onBlockPos(start).x + 496, onBlockPos(start).y)
					GameManager.players[player].end = Vector2i(onBlockPos(end).x + 496, onBlockPos(end).y)
				else:
					GameManager.players[player].spawn = onBlockPos(start)
					GameManager.players[player].end = onBlockPos(end)
	else:
		$MusicPlayer.play(GameManager.music_progress)  
		AudioServer.set_bus_mute((AudioServer.get_bus_index("Music")),save_file.toggled_sound) 
		remove_child(get_node('Control'))
		switch_btn.visible = true
		quit_btn.visible = true
		var current_player = player_scene.instantiate()
		add_child(current_player)
		for spawn in get_tree().get_nodes_in_group("PlayerSpawnPoint"):
			current_player.global_position = spawn.global_position
		loadLevel()
		player = current_player
		
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
	if(GameManager.is_solo):
		$timer.hide()
	else:
		$timer.show()
		$timer.set_text(str(round($ConstructionTimer.get_time_left()))+"s")
		if($ConstructionTimer.get_time_left() == 0):
			$timer.set_text(str(round($PlayTimer.get_time_left()))+"s")
		await get_tree().create_timer(0.3).timeout
		can_build = true
		

@rpc("any_peer", "call_local")
func graceTime():
	if play_timer.get_time_left() < 60:
		play_timer.set("wait_time",60)
		play_timer.start()
		$timer.set("theme_override_colors/font_color","green")
		await get_tree().create_timer(2.0).timeout
		$timer.set("theme_override_colors/font_color","white")

func startBlockCoords(padding):
	var startx = randi_range(x1_min,x1_max-1)
	var starty = randi_range(y_min,y_max-1)
	
	return Vector2i(startx,starty)
	
func finishBlockCoords(start_block_coords,padding):
	var endx = randi_range(x1_min,x1_max-1)
	var endy = randi_range(y_min,y_max-1)
	if endx > start_block_coords.x-(padding+2) && endx < start_block_coords.x+(padding+2):
		endy = finishCoords(start_block_coords.y,padding,y_min,y_max-1,2)
		
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
	tile_map_no_collision.clear_layer(ground_layer)
	cursor_item = null
	bloc_coord = null

func _on_button_pressed():
	bloc_coord = Vector2i(12,9)
	
func _on_button2_pressed():
	bloc_coord = Vector2i(17,9)
	
func _on_erase_pressed():
	bloc_coord = erase_texture
	
func _on_kill_pressed():
	player.kill()
	
func _on_saw_pressed():
	cursor_item = get_node("Items/Saw")
	
func _on_spike_pressed():
	cursor_item = get_node("Items/Spike")
		
@rpc("any_peer", "call_local")			
func switchPos():
	if !GameManager.is_solo:
		var tempSpawn = GameManager.players[str(multiplayer.get_unique_id())].spawn
		for player in GameManager.players:
			if(GameManager.players[str(multiplayer.get_unique_id())] != GameManager.players[player]):
				GameManager.players[str(multiplayer.get_unique_id())].spawn = GameManager.players[player].spawn
				GameManager.players[player].spawn = tempSpawn

func _input(event):
	if GameManager.is_solo == false:
		if Input.is_action_pressed("click"):
			var mouse_pos = get_global_mouse_position()
			tile_map_pos = tile_map.local_to_map(mouse_pos)
			if can_build:
				if $MultiplayerSynchronizer.get_multiplayer_authority() == GameManager.players[str(multiplayer.get_unique_id())].index && mouse_pos.x < 16*31:
					placeBlock(tile_map_pos, mouse_pos)
				elif $MultiplayerSynchronizer.get_multiplayer_authority() != GameManager.players[str(multiplayer.get_unique_id())].index && mouse_pos.x > 16*31:
					placeBlock(tile_map_pos, mouse_pos)
				
		if event is InputEventMouseMotion:
			var mouse_pos = get_global_mouse_position()
			if (mouse_pos.y <= 512):
				if bloc_coord:
					tile_map_pos = tile_map_no_collision.local_to_map(mouse_pos)
					tile_map_no_collision.clear_layer(ground_layer)
					tile_map_no_collision.set_cell(ground_layer, tile_map_pos, source_id, bloc_coord)
					tile_map_no_collision.set_layer_modulate(ground_layer, Color.WHITE)
					if bloc_coord != erase_texture:
						tile_map_no_collision.set_layer_modulate(ground_layer, Color(Color.WHITE, 0.5))
						
				if cursor_item:
					sprite = cursor_item.get_node("Sprite")
					sprite.set_global_position(Vector2(2000,2000))
					if str(cursor_item).contains("Saw"):
						sprite.set_global_position(Vector2i(tile_map_no_collision.local_to_map(mouse_pos).x * GameManager.TILE_SIZE + GameManager.TILE_SIZE/2, tile_map_no_collision.local_to_map(mouse_pos).y * GameManager.TILE_SIZE + GameManager.TILE_SIZE/2))
					else:
						sprite.set_global_position(Vector2i(tile_map_no_collision.local_to_map(mouse_pos).x * GameManager.TILE_SIZE, tile_map_no_collision.local_to_map(mouse_pos).y * GameManager.TILE_SIZE))
					if str(cursor_item).contains("Spike"):
						cursor_item.change_rotation(cursor_item)
					sprite.set_modulate(Color(Color.WHITE,0.5))
				
				
func placeBlock(tile_map_pos, mouse_pos):
	if (mouse_pos.y <= 512 and !GameManager.indestructibles.has(tile_map.get_cell_atlas_coords(ground_layer,tile_map_pos))):
				
			if cursor_item and cursor_item.can_place:
				rpc("rpc_place_item", cursor_item.get_path(), mouse_pos + cursor_item.offset, cursor_item.get_global_rotation(), cursor_item.offset)
			
			if bloc_coord:
				rpc("rpc_erase", ground_layer, tile_map_pos)
				if (bloc_coord != erase_texture):
					rpc("rpc_place", ground_layer, tile_map_pos, source_id, bloc_coord)

@rpc("any_peer", "call_local")
func rpc_erase(layer, pos):
	tile_map.erase_cell(layer, pos)
	for item in items:
		if tile_map.local_to_map(item.position-Vector2i(item.offset)) == pos:
			items.erase(item)
			for items in items_to_maybe_delete:
				if tile_map.local_to_map(items.position-item.offset) == pos:
					items.queue_free()
					items_to_maybe_delete.erase(items)


@rpc("any_peer", "call_local")
func rpc_place(layer, pos, id, coord):
	tile_map.set_cell(layer, pos, id, coord)
	
@rpc("any_peer", "call_local")
func rpc_place_item(cursor_item, pos, rotation, offset):
	pos = Vector2i(tile_map_no_collision.local_to_map(pos).x * GameManager.TILE_SIZE + GameManager.TILE_SIZE/2, tile_map_no_collision.local_to_map(pos).y * GameManager.TILE_SIZE + GameManager.TILE_SIZE/2)
	var currentItem = {}
	var itemName
	var item = get_node(cursor_item).load_item()
	if str(cursor_item).contains("Saw"):
		currentItem = {
			"name" : "Saw",
			"position" : pos,
			"rotation" : rotation,
			"offset" : offset
		}
		itemName = "Saw"
		items.append(currentItem)
	if str(cursor_item).contains("Spike"):
		currentItem = {
			"name" : "Spike",
			"position" : pos,
			"rotation" : rotation,
			"offset" : offset
		}
		items.append(currentItem)
		itemName = "Spike"
	item.set_global_rotation(rotation)
	var positionOfItem = item.set_tile_position(pos, itemName)
	items_to_maybe_delete.append(item)
	add_child(item)

func _on_round_timer_timeout():
	if !GameManager.is_solo:
		can_build = false
		switchPos()
		print("Construction done Now play !")
		player.kill()
		cursor_item = null
		bloc_coord = null
		GameManager.can_finish_level = true
		remove_child(get_node('Control'))
		play_timer.start()
		if sprite:
			sprite.set_global_position(Vector2(2000,2000))
		tile_map_no_collision.clear_layer(ground_layer)
		grid.is_drawing_grid = false
		grid.queue_redraw()
	
func _on_play_timer_timeout():
	finishGame()
	
@rpc("any_peer", "call_local")
func finishGame():
	print("End of the game go to the scoreboard.")
	if(GameManager.can_confirm_level):
		for player in GameManager.players:
			if(GameManager.players[player].completionPoints > 0):
				GameManager.players[player].penaltyPoints -= 400
	for player in GameManager.players:
		GameManager.players[player].totalPoints += GameManager.players[player].completionPoints + GameManager.players[player].validationPoints + GameManager.players[player].penaltyPoints
		print(str(GameManager.players[player].name)+": "+str(GameManager.players[player].points)+" (c: "+str(GameManager.players[player].completionPoints)+", v: "+str(GameManager.players[player].validationPoints)+", p: "+str(GameManager.players[player].penaltyPoints)+")")
	saveGameDatas()
	get_tree().root.add_child(scene)
	self.queue_free()
	
	for player in GameManager.players:
		GameManager.players[player].spawn = Vector2i(200,1000)
	GameManager.can_finish_level = false
	GameManager.can_confirm_level = false
	
@rpc("any_peer", "call_local")
func updateStartEnd(newStart, newEnd):
	start = newStart
	end = newEnd

func saveGameDatas():
	SaveTilemap.save_data(tile_map, Vector2i(onBlockPos(start).x,onBlockPos(start).y), Vector2i(onBlockPos(start).x+496,onBlockPos(start).y), items)
		
func loadLevel():
	for cell in tile_map.get_used_cells(0):
		tile_map.set_cell(0, cell, -1)
	var game_data = SaveTilemap.load_data(GameManager.load_level)
	for cell_str in game_data["tilemap"].keys():
		var components = cell_str.split(",")
		var x = int(components[0])
		var y = int(components[1])
		var id = game_data["tilemap"][cell_str][0]
		var atlas = game_data["tilemap"][cell_str][1]
		var alternate = game_data["tilemap"][cell_str][2]
		tile_map.set_cell(0, Vector2i(x, y), id, atlas, alternate)
	print(game_data["start"])
	GameManager.solo_spawn = game_data["start"]
	solo_spawn = game_data["start"]
	GameManager.solo_spawn2 = game_data["start2"]
	for _i in game_data["items"]:
		var item
		item = get_node(str("Items/"+_i.name)).load_item()
		item.set_global_rotation(_i.rotation)
		item.set_tile_position(_i.position, _i.name)
		add_child(item)
		pass


func _on_switch_pos_button_down():
	if solo_spawn == GameManager.solo_spawn:
		GameManager.solo_spawn = GameManager.solo_spawn2
		player.kill()
	else:
		GameManager.solo_spawn = solo_spawn
		player.kill()
	switch_btn.release_focus()


func _on_quit_button_down():
	for scenes in get_tree().root.get_children():
		if scenes != get_tree().current_scene and scenes.name != "GameManager" and scenes.name != "SaveFile" and scenes.name != "SaveTilemap":
			get_tree().root.remove_child(scenes)
	scene2 = load("res://control.tscn").instantiate()
	get_tree().root.add_child(scene2)
	self.queue_free()
	pass # Replace with function body.

func _exit_tree():
	GameManager.music_progress = $MusicPlayer.get_playback_position()  
