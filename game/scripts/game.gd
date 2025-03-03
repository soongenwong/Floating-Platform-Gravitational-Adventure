extends Node2D

@onready var multiplayer_ui = $UI/Multiplayer
var peer = ENetMultiplayerPeer.new()

func _on_player_1_pressed() -> void:
	peer.create_server(25565)
	multiplayer.multiplayer_peer = peer
	
	multiplayer.peer_connected.connect(
		func(pid):
			print("peer " + str(pid) + " has joined the game")
	)
	multiplayer_ui.hide()


func _on_player_2_pressed() -> void:
	peer.create_client("localhost", 25565)
	multiplayer.multiplayer_peer = peer
	multiplayer_ui.hide()
