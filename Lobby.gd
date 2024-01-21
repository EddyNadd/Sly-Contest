extends Node
class_name Lobby

var host_id: int
var players : Dictionary = {}
var time_stamp : int = Time.get_unix_time_from_system()

func _init(id):
	host_id = id
	
func addPlayer(id, name):
	players[id] = {
		"name" : name,
		"id" : id,
		"index" : players.size() + 1
	}
	return players[id]
