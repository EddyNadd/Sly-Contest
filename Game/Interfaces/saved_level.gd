extends Control
@onready var levelList = $ItemList

var levelListArray = []

@onready var scene = preload("res://control.tscn").instantiate()
@onready var btnLoad = $Load
@onready var save_file = SaveFile.game_data

# Called when the node enters the scene tree for the first time.
func _ready():
	AudioServer.set_bus_mute((AudioServer.get_bus_index("Music")),save_file.toggledSound) 
	$MusicPlayer.play(GameManager.musicProgress)  
	GameManager.isSolo = true
	if !GameManager.isInSave:
		GameManager.isInSave = true
		for scenes in get_tree().root.get_children():
			if scenes.name == "Control":
				get_tree().current_scene = scenes
				get_tree().reload_current_scene()
	else:
		for scenes in get_tree().root.get_children():
			if scenes.name != "SavedLevel" and scenes.name != "GameManager" and scenes.name != "SaveFile" and scenes.name != "SaveTilemap":
				get_tree().root.remove_child(scenes)
	var dir = DirAccess.open("user://levels/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir():
				if file_name.ends_with("SLAY"):
					levelList.add_item(file_name.substr(0, file_name.length() - 5))
					levelListArray.append(file_name.substr(0, file_name.length() - 5))
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_back_button_down():
	GameManager.isInSave = false
	get_tree().root.add_child(scene)
	pass # Replace with function body.


func _on_load_button_down():
	GameManager.isInSave = false
	btnLoad.release_focus()
	GameManager.loadLevel = levelList.get_item_text(levelList.get_selected_items()[0])
	get_tree().change_scene_to_file("res://Game/Levels/level.tscn")
	pass # Replace with function body.

func _exit_tree():
	GameManager.musicProgress = $MusicPlayer.get_playback_position()  
