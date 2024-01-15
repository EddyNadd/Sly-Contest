extends Control

enum Message {
	id,
	join,
	userConnected,
	userDisconnected,
	lobby,
	candidate,
	offer,
	answer,
	removeLobby,
	checkIn
}

@onready var scene = load("res://Game/Levels/level.tscn").instantiate()

@onready	var player1_NameLabel = $"MarginContainer/VBoxContainer/Player 1"
@onready	var player1_CompletionPointsLabel = $MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer/LevelPoint2
@onready	var player1_ValidationPointsLabel = $MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer2/ValidationPoint2
@onready	var player1_PenaltyPointsLabel = $MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer3/PenalityPoint2
@onready	var player1_TotalPointsLabel = $MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer4/TotalScore2
	
@onready	var player2_NameLabel = $"MarginContainer2/VBoxContainer/Player 2"
@onready	var player2_CompletionPointsLabel = $MarginContainer2/VBoxContainer/VBoxContainer/HBoxContainer/LevelPoint2
@onready	var player2_ValidationPointsLabel = $MarginContainer2/VBoxContainer/VBoxContainer/HBoxContainer2/ValidationPoint2
@onready	var player2_PenaltyPointsLabel = $MarginContainer2/VBoxContainer/VBoxContainer/HBoxContainer3/PenalityPoint2
@onready	var player2_TotalPointsLabel = $MarginContainer2/VBoxContainer/VBoxContainer/HBoxContainer4/TotalScore2


# Called when the node enters the scene tree for the first time.
func _ready():
	for player in GameManager.Players:
		if (GameManager.Players[player].index == 1):
			player1_NameLabel.text = str(GameManager.Players[player].name)
			player1_CompletionPointsLabel.text = str(GameManager.Players[player].completionPoints)
			player1_ValidationPointsLabel.text = str(GameManager.Players[player].validationPoints)
			player1_PenaltyPointsLabel.text = str(GameManager.Players[player].penaltyPoints)
			player1_TotalPointsLabel.text = str(GameManager.Players[player].totalPoints)
		else:
			player2_NameLabel.text = str(GameManager.Players[player].name)
			player2_CompletionPointsLabel.text = str(GameManager.Players[player].completionPoints)
			player2_ValidationPointsLabel.text = str(GameManager.Players[player].validationPoints)
			player2_PenaltyPointsLabel.text = str(GameManager.Players[player].penaltyPoints)
			player2_TotalPointsLabel.text = str(GameManager.Players[player].totalPoints)


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
	GameManager.finished = true
	self.queue_free()
	


func _on_save_pressed():
	if $MarginContainer2/VBoxContainer/HBoxContainer/TextEdit.text != "":
		SaveTilemap.write_data($MarginContainer2/VBoxContainer/HBoxContainer/TextEdit.text)

