extends Control
@onready var save_file = SaveFile.game_data
@onready var mainMenu = preload("res://Game/Interfaces/main_menu.tscn") as PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	AudioServer.set_bus_mute((AudioServer.get_bus_index("Music")),save_file.toggled_sound) 
	$MusicPlayer.play(GameManager.music_progress) 

func _on_quit_pressed():
	get_tree().change_scene_to_packed(mainMenu)

func _exit_tree():
	GameManager.music_progress = $MusicPlayer.get_playback_position()   
