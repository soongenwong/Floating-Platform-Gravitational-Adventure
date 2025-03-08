extends Node

var winner_text = ""
var buffer = ""
var other_player_nodes = {}
var last_update_time = 0
var update_frequency = 0.05

var socket = StreamPeerTCP.new()
func _ready():
	if GameManager.player:
		print("Connecting to server...")
		var error = socket.connect_to_host("18.170.218.235", 12000) # Aaditya's EC2 instance IP.
		if error != OK:
			print("Error connecting: " + str(error))
			
	
func _process(_delta):
	print(GameManager.player_pos.x)
	print(GameManager.player_pos.y)
	send_player_position()

    last_update_time += delta
    if last_update_time >= update_frequency:
        send_player_position()
        last_update_time = 0
        
	socket.poll()

	var status = socket.get_status()
	if status == StreamPeerTCP.STATUS_CONNECTED:
		var received_data = socket.get_available_bytes()
		if received_data > 0:
			var raw_data = socket.get_string(received_data)  # Read full incoming message
			buffer += raw_data  # Append to buffer in case of fragmentation

			# Try parsing JSON
			var json = JSON.new()
			var parse_result = json.parse(buffer)

			if parse_result == OK:
                var parsed_data = json.get_data()
                if parsed_data is Dictionary:
                    if parsed_data.has("type"):
                        # Handle different message types
                        if parsed_data["type"] == "platform_data":
                            load_platform_data(parsed_data)
                        elif parsed_data["type"] == "player_positions":
                            update_other_players(parsed_data["players"])
                        elif parsed_data["type"] == "player_disconnected":
                            remove_player(parsed_data["player_id"])
                    else:
                        # For backward compatibility with existing code
                        load_platform_data(parsed_data)
                    buffer = ""
                else:
                    print("Received malformed JSON data")

func send_player_position():
	var position_data = {
		"player_id": GameManager.player_id,
		"player_x": GameManager.player_pos.x,
		"player_y": GameManager.player_pos.y
	}
	var json = JSON.new()
	var json_string = json.stringify(position_data)
	
	socket.put_string(json_string + "\n") # Send data as JSON string

func _exit_tree():
	socket.disconnect_from_host()

func load_platform_data(parsed_data):
	print("Received platform data: ", parsed_data)

	# Load data into GameManager arrays
	if parsed_data.has("Platforms"):
		GameManager.platform_pos = parsed_data["Platforms"]
	if parsed_data.has("BreakingPlatforms"):
		GameManager.platform_break_pos = parsed_data["BreakingPlatforms"]
	if parsed_data.has("MovingPlatforms"):
		GameManager.platform_moving_pos = parsed_data["MovingPlatforms"]

    #load the other player's postions
    if parsed_data.has("Players"):
        update_other_players(parsed_data["Players"])

	print("Server data loaded successfully!")

func update_other_players(players_data):
    for player_data in players_data:
        if player_data.player_id == GameManager.player_id:
            continue
            
        var player_id = player_data.player_id
        var player_x = player_data.player_x
        var player_y = player_data.player_y

        if not other_player_nodes.has(player_id):
            create_other_player(player_id)
        
        if other_player_nodes.has(player_id):
            other_player_nodes[player_id].position = Vector2(player_x, player_y)
