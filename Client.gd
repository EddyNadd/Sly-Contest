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

var current_scene = null

var peer = WebSocketMultiplayerPeer.new()

var id = 0
 
var ip = "localhost" # prod ip

# var ip = "127.0.0.1" # dev ip

var rtcPeer : WebRTCMultiplayerPeer = WebRTCMultiplayerPeer.new()

var hostId : int

var lobbyValue = ""

var connectedStatus = false

@onready var startGameBtn = $"../StartGame"
@onready var lobbyBtn = $"../JoinLobby"
@onready var copyBtn = $"../Copy"
@onready var lobbyCode = $"../lobbyCode"
@onready var lobbyCodeLabel = $"LineEdit"
@onready var copyStatus = $"../CopyStatus"
@onready var globalStatus = $"../GlobalStatus"
@onready var leaveBtn = $"../LeaveLobby"
@onready var loadBtn = $"../Load Level"
@onready var username = $Username
@onready var userList = $"../ItemList"
@onready var back = $"../Back"
@onready var serverMod = $"../ServerMod"
@onready var serverModImage = $"../ServerModImage"
@onready var scene = load("res://Game/Levels/level.tscn").instantiate()
@onready var scene2 = load("res://Game/Interfaces/saved_level.tscn").instantiate()
@onready var scene3 = load("res://control.tscn").instantiate()
@onready var scene4 = load("res://Game/Interfaces/main_menu.tscn").instantiate()
@onready var save_file = SaveFile.game_data
@onready var global = $".."

# Called when the node enters the scene tree for the first time.
func _ready():
	if "--server" in OS.get_cmdline_user_args() or GameManager.serverLaunch == true:
		print("Server mod!")
		for scenes in get_tree().root.get_children():
			if scenes.name != "Control" and scenes.name != "GameManager" and scenes.name != "SaveFile" and scenes.name != "SaveTilemap":
				get_tree().root.remove_child(scenes)
		startGameBtn.hide()
		lobbyBtn.hide()
		copyBtn.hide()
		lobbyCode.hide()
		lobbyCodeLabel.hide()
		copyStatus.hide()
		globalStatus.hide()
		leaveBtn.hide()
		loadBtn.hide()
		username.hide()
		userList.hide()
		back.hide()
		serverModImage.visible = true
		serverMod.visible = true
	else:
		if !GameManager.isInSave or !GameManager.isInMenu:
			for scenes in get_tree().root.get_children():
				if scenes.name != "Control" and scenes.name != "GameManager" and scenes.name != "SaveFile" and scenes.name != "SaveTilemap":
					get_tree().root.remove_child(scenes)
			for scenes in get_tree().root.get_children():
				if scenes.name == "Control":
					get_tree().current_scene = scenes
		else:
			global.visible = false
			lobbyCodeLabel.visible = false
			username.visible = false
			
		username.text = save_file.username
		multiplayer.connected_to_server.connect(RTCServerConnected)
		multiplayer.peer_connected.connect(RTCPeerConnected)
		multiplayer.peer_disconnected.connect(RTCPeerDisconnected)
		connectToServer(save_file.server)
	$MusicPlayer.play(GameManager.musicProgress)
	AudioServer.set_bus_mute((AudioServer.get_bus_index("Music")),save_file.toggledSound) 
	  
	
func RTCServerConnected():
	print("RTC server connected")
	
func RTCPeerConnected(id):
	connectedStatus = true
	print("RTC peer connected " + str(id))
	
func RTCPeerDisconnected(id):
	print("RTC peer disconnected " + str(id))
	connectedStatus = false
	GameCrash(id)

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
				if JSON.parse_string(data.players).size() == 1:
					var newPlayers = JSON.parse_string(data.players)
					print(newPlayers)
					for key in newPlayers.keys():
						if newPlayers[key].index == 2:
							leaveLobby()
							OS.alert('The player hosting the lobby deleted it.', 'Lobby information')
							for scenes in get_tree().root.get_children():
								if scenes.name == "Control":
									get_tree().current_scene = scenes
							get_tree().reload_current_scene()
							connectedStatus = false
							lobbyValue = null
				GameManager.Players = JSON.parse_string(data.players)
				hostId = data.host
				lobbyValue = data.lobbyValue
				lobbyCode.text = lobbyValue
				lobbyCodeLabel.text = lobbyValue
				GameManager.lobby = lobbyValue
				globalStatus.text = "Lobby joined !"
				userList.clear()
				for player in GameManager.Players:
					print("RTC CODE " + str(player))
					userList.add_item(GameManager.Players[player].name)
					GameManager.Players[player].totalPoints = 0
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
	if GameManager.finished:
		GameCrash(-1)
		GameManager.finished = false

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
		if GameManager.serverReachable == false:
			if GameManager.isInSave:
				get_tree().change_scene_to_file("res://Game/Interfaces/saved_level.tscn")
			if GameManager.isInMenu:
				get_tree().change_scene_to_file("res://Game/Interfaces/main_menu.tscn")
			break
		if peer.get_connection_status() == 2:
			globalStatus.text = "Connected !"
			if GameManager.isInSave:
				get_tree().change_scene_to_file("res://Game/Interfaces/saved_level.tscn")
			if GameManager.isInMenu:
				get_tree().change_scene_to_file("res://Game/Interfaces/main_menu.tscn")
			break	
		else:
			globalStatus.text = "Connecting to server... Please wait for response before doing anything."
	if peer.get_connection_status() == 0:
		GameManager.serverReachable = false
		globalStatus.text = "Servers unreachable..."

func _on_button_button_down():
	if peer.get_connection_status() != 1:
		if peer.get_connection_status() == 0:
			globalStatus.text = "Servers unreachable..."
		elif lobbyValue:
			if len(GameManager.Players) == 2 && connectedStatus:
				StartGame.rpc()
				startGameBtn.release_focus()
			elif !connectedStatus:
				globalStatus.text = "Waiting for peer connection..."
			else:
				globalStatus.text = "Not enough players..."
		else:
			globalStatus.text = "An error occured..."
		pass # Replace with function body.

@rpc("any_peer", "call_local")
func StartGame():
	removeLobby()
	get_tree().root.add_child(scene)
	
func GameCrash(idPeer):
	var hasLevel = false
	if get_tree().root.get_children():
		for scenes in get_tree().root.get_children():
			if scenes.name == "Level" or scenes.name == "ScoreBoard":
				hasLevel = true
			if scenes.name != "Control" and scenes.name != "GameManager" and scenes.name != "SaveFile" and scenes.name != "SaveTilemap":
				get_tree().root.remove_child(scenes)
		if hasLevel:
			get_tree().reload_current_scene()

	var message = {
		"id" : idPeer,
		"message" : Message.userDisconnected,
		"lobbyValue" : lobbyValue
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())

func removeLobby():
	var message = {
		"message": Message.removeLobby,
		"lobbyID": lobbyValue
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())

func _on_join_lobby_button_down():
	if peer.get_connection_status() != 1:
		if username.text:
			if lobbyValue != "":
				globalStatus.text = "You already are in a lobby. Please leave it to join another one."
			else:
				var message = {
					"id" : id,
					"message" : Message.lobby,
					"name" : username.text,
					"lobbyValue" : $LineEdit.text
				}
				peer.put_packet(JSON.stringify(message).to_utf8_buffer())
		else:
			if !username.text:
				globalStatus.text = "Please enter a username..."
		lobbyBtn.release_focus()

func _on_copy_button_down():
	if lobbyValue:
		DisplayServer.clipboard_set(lobbyValue)
		copyStatus.text = "Copied !"
	copyBtn.release_focus()


func _on_leave_lobby_button_down():
	if peer.get_connection_status() != 1:
		if connectedStatus and lobbyValue:
			leaveLobby()
			await get_tree().create_timer(0.1).timeout
			get_tree().reload_current_scene()
			connectedStatus = false
			lobbyValue = null
		elif !connectedStatus and userList.item_count == 1:
			leaveLobby()
			await get_tree().create_timer(0.1).timeout
			get_tree().reload_current_scene()
		leaveBtn.release_focus()
	
func leaveLobby():
	var message = {
		"id" : id,
		"message" : Message.userDisconnected,
		"lobbyValue" : $LineEdit.text
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())

func _on_username_text_changed(new_text):
	save_file.username = new_text
	SaveFile.save_data()

func _on_load_level_button_down():
	if peer.get_connection_status() != 1:
		if connectedStatus and lobbyValue:
			leaveLobby()
			loadBtn.release_focus()
			get_tree().root.add_child(scene2)
		elif !connectedStatus and lobbyValue:
			globalStatus.text = "Leave the lobby before doing any actions."
		else:
			loadBtn.release_focus()
			get_tree().root.add_child(scene2)
		pass # Replace with function body.

func _on_back_button_down():
	if peer.get_connection_status() != 1:
		if connectedStatus and lobbyValue:
			leaveLobby()
			loadBtn.release_focus()
			get_tree().root.add_child(scene4)
		elif !connectedStatus and lobbyValue:
			globalStatus.text = "Leave the lobby before doing any actions."
		else:
			loadBtn.release_focus()
			get_tree().root.add_child(scene4)
	
func _exit_tree():
	GameManager.musicProgress = $MusicPlayer.get_playback_position() 
