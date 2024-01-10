extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	var player1_NameLabel = $"MarginContainer/VBoxContainer/Player 1"
	var player1_CompletionPointsLabel = $MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer/LevelPoint2
	var player1_ValidationPointsLabel = $MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer2/ValidationPoint2
	var player1_PenaltyPointsLabel = $MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer3/PenalityPoint2
	var player1_TotalPointsLabel = $MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer4/TotalScore2
	
	var player2_NameLabel = $"MarginContainer2/VBoxContainer/Player 2"
	var player2_CompletionPointsLabel = $MarginContainer2/VBoxContainer/VBoxContainer/HBoxContainer/LevelPoint2
	var player2_ValidationPointsLabel = $MarginContainer2/VBoxContainer/VBoxContainer/HBoxContainer2/ValidationPoint2
	var player2_PenaltyPointsLabel = $MarginContainer2/VBoxContainer/VBoxContainer/HBoxContainer3/PenalityPoint2
	var player2_TotalPointsLabel = $MarginContainer2/VBoxContainer/VBoxContainer/HBoxContainer4/TotalScore2
	
	for player in GameManager.Players:
		if (GameManager.Players[player].index == 1):
			player1_NameLabel.text = str(GameManager.Players[player].name)
			player1_CompletionPointsLabel.text = str(GameManager.Players[player].completionPoints)
			player1_ValidationPointsLabel.text = str(GameManager.Players[player].validationPoints)
			player1_PenaltyPointsLabel.text = str(GameManager.Players[player].penaltyPoints)
			player1_TotalPointsLabel.text = str(GameManager.Players[player].points)
		else:
			player2_NameLabel.text = str(GameManager.Players[player].name)
			player2_CompletionPointsLabel.text = str(GameManager.Players[player].completionPoints)
			player2_ValidationPointsLabel.text = str(GameManager.Players[player].validationPoints)
			player2_PenaltyPointsLabel.text = str(GameManager.Players[player].penaltyPoints)
			player2_TotalPointsLabel.text = str(GameManager.Players[player].points)


func _on_quit_pressed():
	get_tree().change_scene_to_file("res://Game/Interfaces/main_menu.tscn")
	
func _on_play_pressed():
	rpc("loadScene")

@rpc("any_peer", "call_local")
func loadScene():
	get_tree().change_scene_to_file("res://Game/Levels/level.tscn")
