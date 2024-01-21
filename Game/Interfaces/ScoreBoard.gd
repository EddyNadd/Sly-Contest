extends Control

@onready var scene = load("res://Game/Levels/level.tscn").instantiate()

@onready	var player1_name_label = $"MarginContainer/VBoxContainer/Player 1"
@onready	var player1_completion_points_label = $MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer/LevelPoint2
@onready	var player1_validation_points_label = $MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer2/ValidationPoint2
@onready	var player1_penalty_points_label = $MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer3/PenalityPoint2
@onready	var player1_total_points_label = $MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer4/TotalScore2
	
@onready	var player2_name_label = $"MarginContainer2/VBoxContainer/Player 2"
@onready	var player2_completion_points_label = $MarginContainer2/VBoxContainer/VBoxContainer/HBoxContainer/LevelPoint2
@onready	var player2_validation_points_label = $MarginContainer2/VBoxContainer/VBoxContainer/HBoxContainer2/ValidationPoint2
@onready	var player2_penalty_points_label = $MarginContainer2/VBoxContainer/VBoxContainer/HBoxContainer3/PenalityPoint2
@onready	var player2_total_points_label = $MarginContainer2/VBoxContainer/VBoxContainer/HBoxContainer4/TotalScore2


# Called when the node enters the scene tree for the first time.
func _ready():
	for player in GameManager.players:
		if (GameManager.players[player].index == 1):
			player1_name_label.text = str(GameManager.players[player].name)
			player1_completion_points_label.text = str(GameManager.players[player].completionPoints)
			player1_validation_points_label.text = str(GameManager.players[player].validationPoints)
			player1_penalty_points_label.text = str(GameManager.players[player].penaltyPoints)
			player1_total_points_label.text = str(GameManager.players[player].totalPoints)
		else:
			player2_name_label.text = str(GameManager.players[player].name)
			player2_completion_points_label.text = str(GameManager.players[player].completionPoints)
			player2_validation_points_label.text = str(GameManager.players[player].validationPoints)
			player2_penalty_points_label.text = str(GameManager.players[player].penaltyPoints)
			player2_total_points_label.text = str(GameManager.players[player].totalPoints)


func _on_quit_pressed():
	loadLobby.rpc()
	
func _on_play_pressed():
	loadScene.rpc()

@rpc("any_peer", "call_local")
func loadScene():
	
	scene = load("res://Game/Levels/level.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.queue_free()
	
@rpc("any_peer", "call_local")
func loadLobby():
	get_tree().change_scene_to_file("res://control.tscn")
	GameManager.is_finished = true
	self.queue_free()
	


func _on_save_pressed():
	if $MarginContainer2/VBoxContainer/HBoxContainer/TextEdit.text != "":
		SaveTilemap.write_data($MarginContainer2/VBoxContainer/HBoxContainer/TextEdit.text)

