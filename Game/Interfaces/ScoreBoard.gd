extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_quit_pressed():
	get_tree().change_scene_to_file("res://Game/Interfaces/main_menu.tscn")
	
func _on_play_pressed():
	rpc("loadScene")

@rpc("any_peer", "call_local")
func loadScene():
	get_tree().change_scene_to_file("res://Game/Levels/level.tscn")
