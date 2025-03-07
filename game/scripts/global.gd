extends Node

var winner_text = ""
var buffer = ""

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
					load_platform_data(parsed_data)  # Call function to load data
					buffer = ""  # Reset buffer after successful parsing
				else:
					print("Received malformed JSON data")
			else:
				print("JSON parsing error: ", json.get_error_message())

func send_player_position():
	var position_data = {
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

	print("Platform data loaded successfully!")
