extends Node

const SAVE_FILE = "user://save_file.save"
var game_data = {}

func _ready():
	load_data()
	
func save_data():
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	file.store_var(game_data)
	file.close()
	
func load_data():
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if not file:
		game_data = {
			"username" : "Username"
		}
		save_data()
	file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	game_data = file.get_var()
	file.close()
