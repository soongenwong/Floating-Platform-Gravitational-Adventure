extends Node

var network = ENetMultiplayerPeer.new()
var port = 8910
var max_players = 2

func _ready():
    start_server()

func start_server():
    network.create_server(port, max_players)
    get_tree().network_peer = network
    print("Server started on port " + str(port))
    
    # Connect signals
    multiplayer.peer_connected.connect(_player_connected)
    multiplayer.peer_disconnected.connect(_player_disconnected)

func _player_connected(player_id):
    print("Player " + str(player_id) + " connected")

func _player_disconnected(player_id):
    print("Player " + str(player_id) + " disconnected")