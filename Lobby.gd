extends Node
class_name Lobby

var HostId : int
var Players : Dictionary = {}

func _init(id):
	HostId = id
	
func AddPlayer(id, name):
	Players[id] = {
		"name" : name,
		"id" : id,
		"index" : Players.size() + 1
	}
	return Players[id]
