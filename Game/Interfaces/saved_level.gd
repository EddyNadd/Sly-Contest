extends Control
@onready var level_list = $ItemList

var level_list_array = []

@onready var scene = preload("res://control.tscn").instantiate()
@onready var btn_load = $Load
@onready var save_file = SaveFile.game_data

# Called when the node enters the scene tree for the first time.
func _ready():
	AudioServer.set_bus_mute((AudioServer.get_bus_index("Music")),save_file.toggled_sound) 
	$MusicPlayer.play(GameManager.music_progress)  
	GameManager.is_solo = true
	if !GameManager.is_in_save:
		GameManager.is_in_save = true
		for scenes in get_tree().root.get_children():
			if scenes.name == "Control":
				get_tree().current_scene = scenes
				get_tree().reload_current_scene()
	else:
		GameManager.serverReachable = true
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
					level_list.add_item(file_name.substr(0, file_name.length() - 5))
					level_list_array.append(file_name.substr(0, file_name.length() - 5))
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_back_button_down():
	GameManager.is_in_save = false
	get_tree().root.add_child(scene)
	pass # Replace with function body.


func _on_load_button_down():
	GameManager.is_in_save = false
	btn_load.release_focus()
	GameManager.load_level = level_list.get_item_text(level_list.get_selected_items()[0])
	get_tree().change_scene_to_file("res://Game/Levels/level.tscn")
	pass # Replace with function body.

func _exit_tree():
	GameManager.music_progress = $MusicPlayer.get_playback_position()  
