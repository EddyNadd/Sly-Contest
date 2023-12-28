extends Control
# Called when the node enters the scene tree for the first time.
var music_bus : int
@onready var soundVolume = $TextureRect/VBoxContainer/HBoxContainer/HSlider
@onready var mainMenu = preload("res://Game/Interfaces/main_menu.tscn") as PackedScene
var saveValue = 1

func _ready():
	var music_bus = AudioServer.get_bus_index("Music")
	

func _on_h_slider_value_changed(value : float) -> void:
	AudioServer.set_bus_volume_db(music_bus, linear_to_db(value))
	saveValue = value
	

func _on_quit_pressed():
	get_tree().change_scene_to_packed(mainMenu)
	

func _on_check_button_toggled(button_pressed):
	if button_pressed==true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	
func _on_sound_toggled(button_pressed):
		AudioServer.set_bus_mute(music_bus, not AudioServer.is_bus_mute(music_bus))
		if AudioServer.is_bus_mute(music_bus):	
			soundVolume.set_value_no_signal(0)
		else:
			soundVolume.set_value_no_signal(saveValue)
