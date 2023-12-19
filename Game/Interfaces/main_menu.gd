class_name MainMenu
extends Control

@onready var play_button = $MarginContainer/HBoxContainer/VBoxContainer/Play as Button
@onready var option_button = $MarginContainer/HBoxContainer/VBoxContainer/Option as Button
@onready var credit_button = $MarginContainer/HBoxContainer/VBoxContainer/Credit as Button
@onready var lobby = preload("res://control.tscn") as PackedScene

func _ready():
	if "--server" in OS.get_cmdline_args():
		print("Server mod!")
		get_tree().change_scene_to_file("res://control.tscn")
	pass

func _on_play_pressed():
	play_button.release_focus() 
	get_tree().change_scene_to_packed(lobby)


func _on_option_pressed():
	pass # Replace with function body.


func _on_credit_pressed():
	pass # Replace with function body.
