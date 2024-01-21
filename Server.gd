extends Node

enum Message {
	id,
	join,
	user_connected,
	user_disconnected,
	lobby,
	candidate,
	offer,
	answer,
	remove_lobby
}

var peer = WebSocketMultiplayerPeer.new()
var users = {}
var lobbies = {}
var characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

@export var host_port = 8915

# Called when the node enters the scene tree for the first time.
func _ready():
	if "--server" in OS.get_cmdline_args() or GameManager.server_launch_on == true:
		print("SERVER - " + "Hosting on " + str(host_port))
		peer.create_server(host_port)
	
	# peer.create_server(host_port) # Comment this line when in prod - dev mod
	peer.connect("peer_connected", peer_connected)
	peer.connect("peer_disconnected", peer_disconnected)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# getting datas from clients
	peer.poll()
	if peer.get_available_packet_count() > 0:
		var packet = peer.get_packet()
		if packet != null:
			var dataString = packet.get_string_from_utf8()
			var data = JSON.parse_string(dataString)
			print("SERVER - " + str(data))
			
			if data.message == Message.lobby:
				joinLobby(data)
				
			if data.message == Message.offer || data.message == Message.answer || data.message == Message.candidate:
				print("SERVER - " + "source id is " + str(data.orgPeer))
				sendToPlayer(data.peer, data)
				
			if data.message == Message.remove_lobby:
				if lobbies.has(data.lobbyID):
					lobbies.erase(data.lobbyID)
					
			if data.message == Message.user_disconnected:
				print("SERVER - DISCONNECTING")
				if len(lobbies[data.lobbyValue].players) != 1:
					if lobbies.has(data.lobbyValue):
						lobbies[data.lobbyValue].layers.erase(data.id)
						for p in lobbies[data.lobbyValue].players:
							var lobbyInfo = {
								"message" : Message.lobby,
								"players" : JSON.stringify(lobbies[data.lobbyValue].players),
								"host" : lobbies[data.lobbyValue].host_id,
								"lobbyValue" : data.lobbyValue
							}
							sendToPlayer(p, lobbyInfo)
				else:
					lobbies.erase(data.lobbyValue)
					
	for lobbyValue in lobbies:
		if lobbies[lobbyValue].time_stamp + 300 < Time.get_unix_time_from_system():
			lobbies.erase(lobbyValue)
	pass

func joinLobby(user):
	if user.lobbyValue == "":
		user.lobbyValue = generateRandomString()
		lobbies[user.lobbyValue] = Lobby.new(user.id)
		print("SERVER - " + str(user.lobbyValue))
	var hasLobby = false
	for item in lobbies:
		if item == user.lobbyValue:
			hasLobby = true
	if hasLobby:
		print("SERVER - JOINING MESSAGE")
		var player = lobbies[user.lobbyValue].addPlayer(user.id, user.name)
	
		for p in lobbies[user.lobbyValue].players:
			var data = {
				"message" : Message.user_connected,
				"id" : user.id
			}
			sendToPlayer(p, data)
			var data2 = {
				"message" : Message.user_connected,
				"id" : p
			}
			sendToPlayer(user.id, data2)
			var lobbyInfo = {
				"message" : Message.lobby,
				"players" : JSON.stringify(lobbies[user.lobbyValue].players),
				"host" : lobbies[user.lobbyValue].host_id,
				"lobbyValue" : user.lobbyValue
			}
			sendToPlayer(p, lobbyInfo)
	
		var data = {
			"message" : Message.user_connected,
			"id" : user.id,
			"host" : lobbies[user.lobbyValue].host_id,
			"player" : lobbies[user.lobbyValue].players[user.id],
			"lobbyValue" : user.lobbyValue
		}
		sendToPlayer(user.id, data)

func sendToPlayer(userId, data):
	peer.get_peer(userId).put_packet(JSON.stringify(data).to_utf8_buffer())

func generateRandomString():
	var result = ""
	for i in range(5):
		var index = randi() % characters.length()
		result += characters[index]
	return result

func startServer():
	peer.create_server(host_port)
	print("SERVER - " + "started Server")

func _on_button_2_button_down():
	var message = {
		"message" : Message.id,
		"data" : "test"
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	pass # Replace with function body.
	
func peer_connected(id):
	print("SERVER - " + "Peer Connected " + str(id))
	users[id] = {
		"id" : id,
		"message" : Message.id
	}
	sendToPlayer(id, users[id])
	pass
	
func peer_disconnected(id):
	pass
