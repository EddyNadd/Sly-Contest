extends Control
# Called when the node enters the scene tree for the first time.
var music_bus = AudioServer.get_bus_index("Music")
var SFX_bus = AudioServer.get_bus_index("SFX")
@onready var sound_volume = $TextureRect/VBoxContainer/HBoxContainer/HSlider
@onready var main_menu = preload("res://Game/Interfaces/main_menu.tscn") as PackedScene
@onready var control = preload("res://control.tscn") as PackedScene
@onready var save_file = SaveFile.game_data
@onready var sound_text = $TextureRect/VBoxContainer/HBoxContainer/Label
@onready var sound_button = $TextureRect/VBoxContainer/HBoxContainer2/Sound
@onready var full_screen = $TextureRect/VBoxContainer2/HBoxContainer/fullscreen
@onready var sfx_text = $TextureRect/VBoxContainer3/HBoxContainer/Label
@onready var sfx_button = $TextureRect/VBoxContainer3/HBoxContainer2/SFX
@onready var sfx_slider = $TextureRect/VBoxContainer3/HBoxContainer/SFXSlider
@onready var server = $TextureRect/VBoxContainer4/HBoxContainer2/TextEdit
@onready var sfx_sound = $SFXPlayer
@onready var get_in = true
var save_value
var sfx_value
func _ready():
	$MusicPlayer.play(GameManager.music_progress)  
	save_value = save_file.sound_level
	sfx_value = save_file.sfx_level
	server.text = save_file.server
	if DisplayServer.window_get_mode() == 3:
		full_screen.button_pressed = true
	else:
		full_screen.button_pressed = false
	
	if AudioServer.is_bus_mute(music_bus):
		sound_button.button_pressed = false
		sound_text.text = "0"
	else:
		sound_button.button_pressed = true
		save_value = save_file.sound_level
		sound_text.text = str(save_value*100)
		sound_volume.value = save_value
		
	if AudioServer.is_bus_mute(SFX_bus):
		sfx_button.button_pressed = false
		sfx_text.text = "0"
		
	else:
		sfx_button.button_pressed = true
		sfx_value = save_file.sfx_level
		sfx_text.text = str(sfx_value*100)
		sfx_slider.value = sfx_value 

func _on_h_slider_value_changed(value : float) -> void:
	AudioServer.set_bus_volume_db(music_bus, linear_to_db(value))
	save_value = value
	save_file.sound_level = value
	SaveFile.save_data()
	sound_text.text = str(value*100)
	
func _on_quit_pressed():
	get_tree().change_scene_to_packed(main_menu)
	

func _on_check_button_toggled(button_pressed):
	save_file.full_screen = button_pressed
	SaveFile.save_data()
	if button_pressed==true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_sound_toggled(button_pressed):
	if button_pressed == false : 
		AudioServer.set_bus_mute(music_bus, true)
		save_file.toggled_sound = AudioServer.is_bus_mute(music_bus)
		SaveFile.save_data()
		print(AudioServer.is_bus_mute(music_bus))
		sound_volume.set_value_no_signal(0)
		sound_text.text="0"
	else:
		AudioServer.set_bus_mute(music_bus, false)
		save_file.toggled_sound = AudioServer.is_bus_mute(music_bus)
		SaveFile.save_data()
		sound_volume.set_value_no_signal(save_value)
		sound_text.text = str(save_value*100)
			


func _on_sfx_toggled(button_pressed):
	if button_pressed == false : 
		AudioServer.set_bus_mute(SFX_bus, true)
		save_file.toggledSFX = AudioServer.is_bus_mute(SFX_bus)
		SaveFile.save_data()
		print(AudioServer.is_bus_mute(SFX_bus))
		sfx_slider.set_value_no_signal(0)
		sfx_text.text="0"
		get_in = false
	else:
		AudioServer.set_bus_mute(SFX_bus, false)
		save_file.toggledSFX = AudioServer.is_bus_mute(SFX_bus)
		SaveFile.save_data()
		sfx_slider.set_value_no_signal(sfx_value)
		sfx_text.text = str(sfx_value*100)
		if get_in == false :
			sfx_sound.play()
		


func _on_sfx_slider_value_changed(sValue : float) -> void:
	AudioServer.set_bus_volume_db(SFX_bus, linear_to_db(sValue))
	sfx_value = sValue
	save_file.sfx_level = sValue
	SaveFile.save_data()
	sfx_text.text = str(sValue*100)
	


func _on_sfx_slider_drag_ended(value_changed):
	sfx_sound.play()
	
func _exit_tree():
	GameManager.music_progress = $MusicPlayer.get_playback_position()   
	


func _on_text_edit_text_changed():
	if server.text == "":
		save_file.server = "localhost"
	else:
		save_file.server = server.text
	pass # Replace with function body.


func _on_button_button_down():
	GameManager.server_launch_on = true
	get_tree().change_scene_to_packed(control)
	pass # Replace with function body.
