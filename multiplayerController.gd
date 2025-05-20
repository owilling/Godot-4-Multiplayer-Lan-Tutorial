extends Control

@export var address = "127.0.0.1"
@export var port = 8910

var peer

func _ready() -> void:
	multiplayer.peer_connected.connect(playerConnected)
	multiplayer.peer_disconnected.connect(playerDisconnected)
	multiplayer.connected_to_server.connect(connectedToServer)
	multiplayer.connection_failed.connect(connectionFailed)
	if "--server" in OS.get_cmdline_args():
		hostGame()
	
	
func hostGame():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, 2)
	if error != OK:
		print("cannot host: " + str(error))
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	print("waiting for players")
#calls on client and server when connected
func playerConnected(id):
	print("Player Connected " + str(id))
#calls on client and server when disconnected
func playerDisconnected(id):
	print("Player Disconnected " + str(id))
	gameManager.players.erase(id)
	var players = get_tree().get_nodes_in_group("player")
	for i in players:
		if i.name == str(id):
			i.queue_free()
#called when a client connects to a server
func connectedToServer():
	print("Connected to Server")
	sendPlayerInformation.rpc_id(1, $lineEdit.text, multiplayer.get_unique_id()) #sends the player logging in's information to server
#called when a client connects to a server
func connectionFailed():
	print("Connection Failed")

@rpc("any_peer")
func sendPlayerInformation(name, id):
	#sends information to server
	if !gameManager.players.has(id):
		gameManager.players[id] = {
			"name": name,
			"id": id,
			"score": 0
		}
	#server sends to all the other connected players
	if multiplayer.is_server():
		for i in gameManager.players:
			sendPlayerInformation.rpc(gameManager.players[i].name, i)

#rpc will call the function across all connected clients
@rpc("any_peer","call_local")
func startGame():
	var scene = load("res://testScene.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()

func _on_host_pressed() -> void:
	hostGame()
	sendPlayerInformation($lineEdit.text, multiplayer.get_unique_id())

func _on_join_pressed() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_client(address, port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)

func _on_start_game_pressed() -> void:
	startGame.rpc()
