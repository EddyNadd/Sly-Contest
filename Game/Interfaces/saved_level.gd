extends Control
@onready var levelList = $ItemList

var levelListArray = []

# Called when the node enters the scene tree for the first time.
func _ready():
	GameManager.isSolo = true
	var dir = DirAccess.open("user://levels/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir():
				if file_name.ends_with("SLAY"):
					levelList.add_item(file_name.substr(0, file_name.length() - 5))
					levelListArray.append(file_name.substr(0, file_name.length() - 5))
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_back_button_down():
	get_tree().change_scene_to_file("res://control.tscn")
	pass # Replace with function body.


func _on_load_button_down():
	GameManager.loadLevel = levelList.get_item_text(levelList.get_selected_items()[0])
	get_tree().change_scene_to_file("res://Game/Levels/level.tscn")
	pass # Replace with function body.
