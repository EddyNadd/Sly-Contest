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

var id = 0
 
var ip = "localhost"

var rtcPeer : WebRTCMultiplayerPeer = WebRTCMultiplayerPeer.new()

var hostId : int

var lobbyValue = ""

@onready var button = $"../Button"
@onready var button2 = $"../JoinLobby"
@onready var button3 = $"../Start Client"

# Called when the node enters the scene tree for the first time.
func _ready():
	multiplayer.connected_to_server.connect(RTCServerConnected)
	multiplayer.peer_connected.connect(RTCPeerConnected)
	multiplayer.peer_disconnected.connect(RTCPeerDisconnected)
	connectToServer(ip)
	pass # Replace with function body.
	
func RTCServerConnected():
	print("RTC server connected")
	
func RTCPeerConnected(id):
	print("RTC peer connected " + str(id))
	
func RTCPeerDisconnected(id):
	print("RTC peer disconnected " + str(id))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	peer.poll()
	if peer.get_available_packet_count() > 0:
		var packet = peer.get_packet()
		if packet != null:
			var dataString = packet.get_string_from_utf8()
			var data = JSON.parse_string(dataString)
			print(data)
			if data.message == Message.id:
				id = data.id
				connected(id)
			if data.message == Message.userConnected:
				#GameManager.Players[data.id] = data.player
				createPeer(data.id)
			if data.message == Message.lobby:
				GameManager.Players = JSON.parse_string(data.players)
				hostId = data.host
				lobbyValue = data.lobbyValue
			if data.message == Message.candidate:
				if rtcPeer.has_peer(data.orgPeer):
					print("Got Candidate: " + str(data.orgPeer) + " my id is " + str(id))
					rtcPeer.get_peer(data.orgPeer).connection.add_ice_candidate(data.mid, data.index, data.sdp)
			if data.message == Message.offer:
				if rtcPeer.has_peer(data.orgPeer):
					rtcPeer.get_peer(data.orgPeer).connection.set_remote_description("offer", data.data)
			if data.message == Message.answer:
				if rtcPeer.has_peer(data.orgPeer):
					rtcPeer.get_peer(data.orgPeer).connection.set_remote_description("answer", data.data)

func connected(id):
	rtcPeer.create_mesh(id)
	multiplayer.multiplayer_peer = rtcPeer
	
#web rtc connection
func createPeer(id):
	if id != self.id:
		var peer : WebRTCPeerConnection = WebRTCPeerConnection.new()
		peer.initialize({
			"iceServers" : [{"urls" : ["stun:stun.l.google.com:19302"]}]
		})
		print("binding id " + str(id) + "my id is" + str(self.id))
		
		peer.session_description_created.connect(self.offerCreated.bind(id))
		peer.ice_candidate_created.connect(self.iceCandidateCreated.bind(id))
		rtcPeer.add_peer(peer, id)
		
		if !hostId == self.id:
			peer.create_offer()
		pass
		
func offerCreated(type, data, id):
	if !rtcPeer.has_peer(id):
		return
		
	rtcPeer.get_peer(id).connection.set_local_description(type, data)
	
	if type == "offer":
		sendOffer(id, data)
	else:
		sendAnswer(id, data)
	pass
	
func sendOffer(id, data):
	var message = {
		"peer" : id,
		"orgPeer" : self.id,
		"message" : Message.offer,
		"data" : data,
		"Lobby" : lobbyValue
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	pass
	
func sendAnswer(id, data):
	var message = {
		"peer" : id,
		"orgPeer" : self.id,
		"message" : Message.answer,
		"data" : data,
		"Lobby" : lobbyValue
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	pass

func iceCandidateCreated(midName, indexName, sdpName, id):
	var message = {
		"peer" : id,
		"orgPeer" : self.id,
		"message" : Message.candidate,
		"mid" : midName,
		"index" : indexName,
		"sdp" : sdpName,
		"Lobby" : lobbyValue
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	pass

func connectToServer(ip):
	ip = "ws://" + str(ip) + ":8915"
	peer.create_client(ip)
	while (peer.get_connection_status() > 0):
		await get_tree().create_timer(0.001).timeout
		if peer.get_connection_status() == 2:
			print("started client")
			break	
		else:
			print("connecting")
	if peer.get_connection_status() == 0:
		print("Failed")


func _on_start_client_button_down():
	button3.release_focus()
	connectToServer("")
	pass # Replace with function body.


func _on_button_button_down():
	StartGame.rpc()
	button.release_focus()
	pass # Replace with function body.

@rpc("any_peer", "call_local")
func StartGame():
	var message = {
		"message": Message.removeLobby,
		"lobbyID": lobbyValue
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	var scene = load("res://Game/Levels/level.tscn").instantiate()
	get_tree().root.add_child(scene)

func _on_join_lobby_button_down():
	var message = {
		"id" : id,
		"message" : Message.lobby,
		"name" : "",
		"lobbyValue" : $LineEdit.text
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	button2.release_focus()
	pass # Replace with function body.
