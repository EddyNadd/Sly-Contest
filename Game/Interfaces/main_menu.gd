extends Control
@onready var save_file = SaveFile.game_data
@onready var scene = preload("res://control.tscn").instantiate()

func _ready():
	AudioServer.set_bus_mute((AudioServer.get_bus_index("Music")),save_file.toggled_sound) 
	$MusicPlayer.play(GameManager.music_progress)  
	if "--server" in OS.get_cmdline_args():
		GameManager.is_in_menu = false
		get_tree().change_scene_to_file("res://control.tscn")
	else:
		if !GameManager.is_in_menu:
			GameManager.is_in_menu = true
			for scenes in get_tree().root.get_children():
				if scenes.name == "Control":
					get_tree().current_scene = scenes
					get_tree().reload_current_scene()
		else:
			GameManager.is_server_reachable = true
			for scenes in get_tree().root.get_children():
				if scenes.name != "Main_Menu" and scenes.name != "GameManager" and scenes.name != "SaveFile" and scenes.name != "SaveTilemap":
					get_tree().root.remove_child(scenes) 

func _on_play_pressed():
	GameManager.is_in_menu = false
	get_tree().root.add_child(scene)


func _on_option_pressed():
	get_tree().change_scene_to_file("res://Game/Interfaces/option_menu.tscn")


func _on_credit_pressed():
	get_tree().change_scene_to_file("res://Game/Interfaces/Credit.tscn")

func _exit_tree():
	GameManager.music_progress = $MusicPlayer.get_playback_position()   

func _on_quit_pressed():
	get_tree().quit()
