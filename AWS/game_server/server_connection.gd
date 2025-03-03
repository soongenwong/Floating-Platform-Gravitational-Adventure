extends Node

var socket = StreamPeerTCP.new()
var server_ip = "18.170.74.19"
var server_port = 8080
var local_ip = "127.0.0.1"
var connected = false
var game_state = {}
var read_buffer = ""
var player_id = ""  

func _ready():
    player_id = str(randi())
    connect_to_server()

func connect_to_server():
    print("Attempting to connect to " + server_ip + ":" + str(server_port))
    var err = socket.connect_to_host(server_ip, server_port)
    if err != OK:
        print("Unable to connect to server: ", err)
    else:
        print("Connection initiated...")

func _process(delta):
    if socket.get_status() == StreamPeerTCP.STATUS_CONNECTING:
        print("Connecting...")
    elif socket.get_status() == StreamPeerTCP.STATUS_CONNECTED:
        if !connected:
            connected = true
            print("Connected to server!")
            register_player()
            
        if socket.get_available_bytes() > 0:
            var data = socket.get_utf8_string(socket.get_available_bytes())
            read_buffer += data
            
            var messages = read_buffer.split("\n")
            if messages.size() > 1:
                read_buffer = messages[messages.size() - 1]
                
                for i in range(messages.size() - 1):
                    var message = messages[i]
                    if message.length() > 0:
                        process_message(message)
    elif socket.get_status() == StreamPeerTCP.STATUS_NONE or socket.get_status() == StreamPeerTCP.STATUS_ERROR:
        if connected:
            connected = false
            print("Disconnected from server")

func register_player():
    if connected:
        var data = {
            "type": "player_register",
            "player_id": player_id
        }
        var json_str = JSON.stringify(data) + "\n"
        socket.put_data(json_str.to_utf8_buffer())

func process_message(message):
    var json = JSON.parse_string(message)
    if json == null:
        print("Failed to parse message: ", message)
        return
        
    if json.has("type"):
        match json.type:
            "state_update":
                game_state = json.data
                update_game_with_state(game_state)
            "player_assigned":
                player_id = json.player_id
                print("Assigned player ID: ", player_id)
            "game_start":
                print("Game started with players: ", json.players)
                # Update UI to show both players are connected
            "game_end":
                print("Game ended. Winner: ", json.winner)

func send_game_action(action_data):
    if connected:
        var data = {
            "type": "player_action",
            "player_id": player_id,
            "action": action_data
        }
        var json_str = JSON.stringify(data) + "\n"
        socket.put_data(json_str.to_utf8_buffer())
        
func update_game_with_state(state):
    
    pass