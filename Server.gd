extends Node

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

var peer = WebSocketMultiplayerPeer.new()
var users = {}
var lobbies = {}
var Characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

@export var hostPort = 8915

# Called when the node enters the scene tree for the first time.
func _ready():
	if "--server" in OS.get_cmdline_args():
		print("Hosting on " + str(hostPort))
		peer.create_server(hostPort)
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
			print(data)
			
			if data.message == Message.lobby:
				JoinLobby(data)
				
			if data.message == Message.offer || data.message == Message.answer || data.message == Message.candidate:
				print("source id is " + str(data.orgPeer))
				sendToPlayer(data.peer, data)
				
			if data.message == Message.removeLobby:
				if lobbies.has(data.lobbyID):
					lobbies.erase(data.lobbyID)
	for lobbyValue in lobbies:
		if lobbies[lobbyValue].TimeStamp + 300 < Time.get_unix_time_from_system():
			lobbies.erase(lobbyValue)
	pass

func JoinLobby(user):
	if user.lobbyValue == "":
		user.lobbyValue = generateRandomString()
		lobbies[user.lobbyValue] = Lobby.new(user.id)
		print(user.lobbyValue)
	var player = lobbies[user.lobbyValue].AddPlayer(user.id, user.name)
	
	for p in lobbies[user.lobbyValue].Players:
		var data = {
			"message" : Message.userConnected,
			"id" : user.id
		}
		sendToPlayer(p, data)
		var data2 = {
			"message" : Message.userConnected,
			"id" : p
		}
		sendToPlayer(user.id, data2)
		var lobbyInfo = {
			"message" : Message.lobby,
			"players" : JSON.stringify(lobbies[user.lobbyValue].Players),
			"host" : lobbies[user.lobbyValue].HostId,
			"lobbyValue" : user.lobbyValue
		}
		sendToPlayer(p, lobbyInfo)
	
	var data = {
		"message" : Message.userConnected,
		"id" : user.id,
		"host" : lobbies[user.lobbyValue].HostId,
		"player" : lobbies[user.lobbyValue].Players[user.id],
		"lobbyValue" : user.lobbyValue
	}
	sendToPlayer(user.id, data)
	
func sendToPlayer(userId, data):
	peer.get_peer(userId).put_packet(JSON.stringify(data).to_utf8_buffer())

func generateRandomString():
	var result = ""
	for i in range(5):
		var index = randi() % Characters.length()
		result += Characters[index]
	return result

func startServer():
	peer.create_server(hostPort)
	print("started Server")

func _on_start_server_button_down():
	startServer()
	pass # Replace with function body.

func _on_button_2_button_down():
	var message = {
		"message" : Message.id,
		"data" : "test"
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	pass # Replace with function body.
	
func peer_connected(id):
	print("Peer Connected " + str(id))
	users[id] = {
		"id" : id,
		"message" : Message.id
	}
	sendToPlayer(id, users[id])
	pass
	
func peer_disconnected(id):
	pass
