extends Control
@onready var save_file = SaveFile.game_data

func _ready():
	print("ready")
	AudioServer.set_bus_mute((AudioServer.get_bus_index("Music")),save_file.toggledSound)
	if "--server" in OS.get_cmdline_args():
		print("Server mod!")
		get_tree().change_scene_to_file("res://control.tscn")
	

func _on_play_pressed():
	print("play")
	get_tree().change_scene_to_file("res://control.tscn")


func _on_option_pressed():
	print("option")
	get_tree().change_scene_to_file("res://Game/Interfaces/option_menu.tscn")


func _on_credit_pressed():
	get_tree().change_scene_to_file("res://Game/Interfaces/Credit.tscn")


func _on_quit_pressed():
	get_tree().quit()
