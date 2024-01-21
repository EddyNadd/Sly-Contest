extends Node
class_name Lobby

var HostID: int
var Players : Dictionary = {}
var TimeStamp : int = Time.get_unix_time_from_system()

func _init(id):
	HostID = id
	
func AddPlayer(id, name):
	Players[id] = {
		"name" : name,
		"id" : id,
		"index" : Players.size() + 1
	}
	return Players[id]
