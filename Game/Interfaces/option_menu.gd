extends Control
# Called when the node enters the scene tree for the first time.
var music_bus = AudioServer.get_bus_index("Music")
var SFX_bus = AudioServer.get_bus_index("SFX")
@onready var soundVolume = $TextureRect/VBoxContainer/HBoxContainer/HSlider
@onready var mainMenu = preload("res://Game/Interfaces/main_menu.tscn") as PackedScene
@onready var save_file = SaveFile.game_data
@onready var soundText = $TextureRect/VBoxContainer/HBoxContainer/Label
@onready var soundButton = $TextureRect/VBoxContainer/HBoxContainer2/Sound
@onready var fullScreen = $TextureRect/VBoxContainer2/HBoxContainer/fullscreen
@onready var sfxText = $TextureRect/VBoxContainer3/HBoxContainer/Label
@onready var sfxButton = $TextureRect/VBoxContainer3/HBoxContainer2/SFX
@onready var sfxSlider = $TextureRect/VBoxContainer3/HBoxContainer/SFXSlider
@onready var sfxSound = $SFXPlayer
@onready var getIn = true
var saveValue
var sfxValue
func _ready():
	saveValue = save_file.soundLevel
	sfxValue = save_file.sfxLevel
	if DisplayServer.window_get_mode() == 3:
		fullScreen.button_pressed = true
	else:
		fullScreen.button_pressed = false
	
	if AudioServer.is_bus_mute(music_bus):
		soundButton.button_pressed = false
		soundText.text = "0"
	else:
		soundButton.button_pressed = true
		saveValue = save_file.soundLevel
		soundText.text = str(saveValue*100)
		soundVolume.value = saveValue
		
	if AudioServer.is_bus_mute(SFX_bus):
		sfxButton.button_pressed = false
		sfxText.text = "0"
		
	else:
		sfxButton.button_pressed = true
		sfxValue = save_file.sfxLevel
		sfxText.text = str(sfxValue*100)
		sfxSlider.value = sfxValue

func _on_h_slider_value_changed(value : float) -> void:
	AudioServer.set_bus_volume_db(music_bus, linear_to_db(value))
	saveValue = value
	save_file.soundLevel = value
	SaveFile.save_data()
	soundText.text = str(value*100)
	
func _on_quit_pressed():
	get_tree().change_scene_to_packed(mainMenu)
	

func _on_check_button_toggled(button_pressed):
	save_file.fullScreen = button_pressed
	SaveFile.save_data()
	if button_pressed==true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_sound_toggled(button_pressed):
	if button_pressed == false : 
		AudioServer.set_bus_mute(music_bus, true)
		save_file.toggledSound = AudioServer.is_bus_mute(music_bus)
		SaveFile.save_data()
		print(AudioServer.is_bus_mute(music_bus))
		soundVolume.set_value_no_signal(0)
		soundText.text="0"
	else:
		AudioServer.set_bus_mute(music_bus, false)
		save_file.toggledSound = AudioServer.is_bus_mute(music_bus)
		SaveFile.save_data()
		soundVolume.set_value_no_signal(saveValue)
		soundText.text = str(saveValue*100)
			


func _on_sfx_toggled(button_pressed):
	if button_pressed == false : 
		AudioServer.set_bus_mute(SFX_bus, true)
		save_file.toggledSFX = AudioServer.is_bus_mute(SFX_bus)
		SaveFile.save_data()
		print(AudioServer.is_bus_mute(SFX_bus))
		sfxSlider.set_value_no_signal(0)
		sfxText.text="0"
		getIn = false
	else:
		AudioServer.set_bus_mute(SFX_bus, false)
		save_file.toggledSFX = AudioServer.is_bus_mute(SFX_bus)
		SaveFile.save_data()
		sfxSlider.set_value_no_signal(sfxValue)
		sfxText.text = str(sfxValue*100)
		if getIn == false :
			sfxSound.play()
		


func _on_sfx_slider_value_changed(sValue : float) -> void:
	AudioServer.set_bus_volume_db(SFX_bus, linear_to_db(sValue))
	sfxValue = sValue
	save_file.sfxLevel = sValue
	SaveFile.save_data()
	sfxText.text = str(sValue*100)
	


func _on_sfx_slider_drag_ended(value_changed):
	sfxSound.play()
	
