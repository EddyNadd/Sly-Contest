extends Node

const SAVE_FILE = "user://save_file.save"
var game_data = {}

func _ready():
	load_data()
	print(game_data)
	var music_bus = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(music_bus, linear_to_db(game_data.soundLevel))
	AudioServer.set_bus_mute(music_bus, game_data.toggledSound)
	if game_data.fullScreen==true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
func save_data():
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	file.store_var(game_data)
	file.close()
	
func load_data():
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if not file:
		game_data = {
			"username" : "Username",
			"soundLevel" : 1,
			"toggledSound" : false,
			"fullScreen" : false
		}
		save_data()
	file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	game_data = file.get_var()
	file.close()
