extends Control
@onready var save_file = SaveFile.game_data
@onready var scene = preload("res://control.tscn").instantiate()

func _ready():
	print("ready")
	AudioServer.set_bus_mute((AudioServer.get_bus_index("Music")),save_file.toggledSound)
	if "--server" in OS.get_cmdline_args():
		GameManager.isInMenu = false
		print("Server mod!")
		get_tree().change_scene_to_file("res://control.tscn")
	else:
		if !GameManager.isInMenu:
			GameManager.isInMenu = true
			for scenes in get_tree().root.get_children():
				if scenes.name == "Control":
					get_tree().current_scene = scenes
					get_tree().reload_current_scene()
		else:
			for scenes in get_tree().root.get_children():
				if scenes.name != "Main_Menu" and scenes.name != "GameManager" and scenes.name != "SaveFile" and scenes.name != "SaveTilemap":
					get_tree().root.remove_child(scenes)
	

func _on_play_pressed():
	print("play")
	GameManager.isInMenu = false
	get_tree().root.add_child(scene)


func _on_option_pressed():
	print("option")
	get_tree().change_scene_to_file("res://Game/Interfaces/option_menu.tscn")


func _on_credit_pressed():
	get_tree().change_scene_to_file("res://Game/Interfaces/Credit.tscn")


func _on_quit_pressed():
	get_tree().quit()
