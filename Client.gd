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

var current_scene = null

var peer = WebSocketMultiplayerPeer.new()

var id = 0
 
var ip = "localhost" # prod ip

# var ip = "127.0.0.1" # dev ip

var rtc_peer : WebRTCMultiplayerPeer = WebRTCMultiplayerPeer.new()

var host_id : int

var lobbyValue = ""

var connected_status = false

@onready var start_game_btn = $"../StartGame"
@onready var lobby_btn = $"../JoinLobby"
@onready var copy_btn = $"../Copy"
@onready var lobbyCode = $"../lobbyCode"
@onready var lobby_code_label = $"LineEdit"
@onready var copy_status = $"../CopyStatus"
@onready var global_status = $"../GlobalStatus"
@onready var leave_btn = $"../LeaveLobby"
@onready var load_btn = $"../Load Level"
@onready var username = $Username
@onready var user_list = $"../ItemList"
@onready var back = $"../Back"
@onready var server_mod = $"../ServerMod"
@onready var server_mod_image = $"../ServerModImage"
@onready var scene = load("res://Game/Levels/level.tscn").instantiate()
@onready var scene2 = load("res://Game/Interfaces/saved_level.tscn").instantiate()
@onready var scene3 = load("res://control.tscn").instantiate()
@onready var scene4 = load("res://Game/Interfaces/main_menu.tscn").instantiate()
@onready var save_file = SaveFile.game_data
@onready var global = $".."

# Called when the node enters the scene tree for the first time.
func _ready():
	if "--server" in OS.get_cmdline_user_args() or GameManager.server_launch_on == true:
		print("Server mod!")
		for scenes in get_tree().root.get_children():
			if scenes.name != "Control" and scenes.name != "GameManager" and scenes.name != "SaveFile" and scenes.name != "SaveTilemap":
				get_tree().root.remove_child(scenes)
		start_game_btn.hide()
		lobby_btn.hide()
		copy_btn.hide()
		lobbyCode.hide()
		lobby_code_label.hide()
		copy_status.hide()
		global_status.hide()
		leave_btn.hide()
		load_btn.hide()
		username.hide()
		user_list.hide()
		back.hide()
		server_mod_image.visible = true
		server_mod.visible = true
	else:
		if !GameManager.is_in_save or !GameManager.is_in_menu:
			for scenes in get_tree().root.get_children():
				if scenes.name != "Control" and scenes.name != "GameManager" and scenes.name != "SaveFile" and scenes.name != "SaveTilemap":
					get_tree().root.remove_child(scenes)
			for scenes in get_tree().root.get_children():
				if scenes.name == "Control":
					get_tree().current_scene = scenes
		else:
			global.visible = false
			lobby_code_label.visible = false
			username.visible = false
			
		GameManager.is_solo = false
		username.text = save_file.username
		multiplayer.connected_to_server.connect(RTCServerConnected)
		multiplayer.peer_connected.connect(RTCPeerConnected)
		multiplayer.peer_disconnected.connect(RTCPeerDisconnected)
		connectToServer(save_file.server)
	$MusicPlayer.play(GameManager.music_progress)
	AudioServer.set_bus_mute((AudioServer.get_bus_index("Music")),save_file.toggled_sound) 
	  
	
func RTCServerConnected():
	print("RTC server connected")
	
func RTCPeerConnected(id):
	connected_status = true
	print("RTC peer connected " + str(id))
	
func RTCPeerDisconnected(id):
	print("RTC peer disconnected " + str(id))
	connected_status = false
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
			if data.message == Message.user_connected:
				#GameManager.players[data.id] = data.player
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
							connected_status = false
							lobbyValue = null
				GameManager.players = JSON.parse_string(data.players)
				host_id = data.host
				lobbyValue = data.lobbyValue
				lobbyCode.text = lobbyValue
				lobby_code_label.text = lobbyValue
				GameManager.lobby = lobbyValue
				global_status.text = "Lobby joined !"
				user_list.clear()
				for player in GameManager.players:
					print("RTC CODE " + str(player))
					user_list.add_item(GameManager.players[player].name)
					GameManager.players[player].totalPoints = 0
			if data.message == Message.candidate:
				if rtc_peer.has_peer(data.orgPeer):
					print("Got Candidate: " + str(data.orgPeer) + " my id is " + str(id))
					rtc_peer.get_peer(data.orgPeer).connection.add_ice_candidate(data.mid, data.index, data.sdp)
			if data.message == Message.offer:
				if rtc_peer.has_peer(data.orgPeer):
					rtc_peer.get_peer(data.orgPeer).connection.set_remote_description("offer", data.data)
			if data.message == Message.answer:
				if rtc_peer.has_peer(data.orgPeer):
					rtc_peer.get_peer(data.orgPeer).connection.set_remote_description("answer", data.data)
	if GameManager.is_finished:
		GameCrash(-1)
		GameManager.is_finished = false

func connected(id):
	rtc_peer.create_mesh(id)
	multiplayer.multiplayer_peer = rtc_peer

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
		rtc_peer.add_peer(peer, id)
		
		if !host_id == self.id:
			peer.create_offer()
		pass
		
func offerCreated(type, data, id):
	if !rtc_peer.has_peer(id):
		return
		
	rtc_peer.get_peer(id).connection.set_local_description(type, data)
	
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
			global_status.text = "Connected !"
			break	
		else:
			global_status.text = "Connecting to server... Please wait for response before doing anything."
	if peer.get_connection_status() == 0:
		global_status.text = "Servers unreachable..."
	if GameManager.is_in_save:
		get_tree().change_scene_to_file("res://Game/Interfaces/saved_level.tscn")
	if GameManager.is_in_menu:
		get_tree().change_scene_to_file("res://Game/Interfaces/main_menu.tscn")

func _on_button_button_down():
	if peer.get_connection_status() != 1:
		if peer.get_connection_status() == 0:
			global_status.text = "Servers unreachable..."
		elif lobbyValue:
			if len(GameManager.players) == 2 && connected_status:
				StartGame.rpc()
				start_game_btn.release_focus()
			elif !connected_status:
				global_status.text = "Waiting for peer connection..."
			else:
				global_status.text = "Not enough players..."
		else:
			global_status.text = "An error occured..."
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
		"message" : Message.user_disconnected,
		"lobbyValue" : lobbyValue
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())

func removeLobby():
	var message = {
		"message": Message.remove_lobby,
		"lobbyID": lobbyValue
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())

func _on_join_lobby_button_down():
	if peer.get_connection_status() != 1:
		if username.text:
			if lobbyValue  != "":
				global_status.text = "You already are in a lobby. Please leave it to join another one."
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
				global_status.text = "Please enter a username..."
		lobby_btn.release_focus()

func _on_copy_button_down():
	if lobbyValue:
		DisplayServer.clipboard_set(lobbyValue)
		copy_status.text = "Copied !"
	copy_btn.release_focus()


func _on_leave_lobby_button_down():
	if peer.get_connection_status() != 1:
		if connected_status and lobbyValue:
			leaveLobby()
			await get_tree().create_timer(0.1).timeout
			get_tree().reload_current_scene()
			connected_status = false
			lobbyValue = null
		elif !connected_status and user_list.item_count == 1:
			leaveLobby()
			await get_tree().create_timer(0.1).timeout
			get_tree().reload_current_scene()
		leave_btn.release_focus()
	
func leaveLobby():
	var message = {
		"id" : id,
		"message" : Message.user_disconnected,
		"lobbyValue" : $LineEdit.text
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())

func _on_username_text_changed(new_text):
	save_file.username = new_text
	SaveFile.save_data()

func _on_load_level_button_down():
	if peer.get_connection_status() != 1:
		if connected_status and lobbyValue:
			leaveLobby()
			load_btn.release_focus()
			get_tree().root.add_child(scene2)
		elif !connected_status and lobbyValue:
			global_status.text= "Leave the lobby before doing any actions."
		else:
			load_btn.release_focus()
			get_tree().root.add_child(scene2)
		pass # Replace with function body.

func _on_back_button_down():
	if peer.get_connection_status() != 1:
		if connected_status and lobbyValue:
			leaveLobby()
			load_btn.release_focus()
			get_tree().root.add_child(scene4)
		elif !connected_status and lobbyValue:
			global_status.text = "Leave the lobby before doing any actions."
		else:
			load_btn.release_focus()
			get_tree().root.add_child(scene4)
	
func _exit_tree():
	GameManager.music_progress = $MusicPlayer.get_playback_position() 
