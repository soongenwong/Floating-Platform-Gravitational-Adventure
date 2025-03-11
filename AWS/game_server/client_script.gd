extends Node

var network = ENetMultiplayerPeer.new()
var ip = "18.170.74.19" # Replace with your EC2's public IP
var port = 8910

func _ready():
    # Add a button to connect to server
    var button = Button.new()
    button.text = "Connect to Server"
    button.pressed.connect(connect_to_server)
    add_child(button)

func connect_to_server():
    network.create_client(ip, port)
    get_tree().network_peer = network
    
    # Connection signals
    multiplayer.connected_to_server.connect(_on_connection_succeeded)
    multiplayer.connection_failed.connect(_on_connection_failed)

func _on_connection_succeeded():
    print("Successfully connected to the server")

func _on_connection_failed():
    print("Failed to connect to the server")