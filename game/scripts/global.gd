extends Node

var winner_text = ""
var buffer = ""
var closing_bracket: bool = 0
	
var socket = StreamPeerTCP.new()
func _ready():
	if GameManager.player:
		print("Connecting to server...")
		var error = socket.connect_to_host("18.170.218.235", 12000) # Aaditya's EC2 instance IP.
		if error != OK:
			print("Error connecting: " + str(error))
	
func _process(_delta):
	socket.poll()
	send_position()
	#print(GameManager.player_pos)

	var status = socket.get_status()
	if status == StreamPeerTCP.STATUS_CONNECTED:
		#print("connected")
		#print("GameManager.platforms_loaded: ", GameManager.platforms_loaded)
		if not GameManager.platforms_loaded:
			var received_data = socket.get_available_bytes()
			#print("received_data: ", received_data)
			if received_data > 0:
				var raw_data = socket.get_string(received_data)  # Read full incoming message
				#print("raw: ", raw_data)
				buffer += raw_data  # Append to buffer in case of fragmentation

				# Try parsing JSON
				var json = JSON.new()
				var parse_result = json.parse(buffer)
				if parse_result == OK:
					#print("OK")
					var parsed_data = json.get_data()
					print("parsed_data: ", parsed_data)
					if parsed_data is Dictionary:
						load_platform_data(parsed_data)  # Call function to load data
						buffer = ""  # Reset buffer after successful parsing
						GameManager.platforms_loaded = 1
					else:
						print("Received malformed JSON data")
				#else:
					#print("JSON parsing error: ", json.get_error_message())
		else:
			if socket.get_available_bytes() > 0:
				# Read the data
				var data = socket.get_data(socket.get_available_bytes())
				if data[0] == OK:
					# Print the received data
					var received_data = data[1].get_string_from_utf8()
					GameManager.other_player_pos = string_to_vector2(received_data)
					var got_id = get_id_0(received_data)
					GameManager.other_id = got_id
					GameManager.other_ready = true
					#print("other pos: id=", got_id, " ", GameManager.other_player_pos)
					#print("my pos: id=", GameManager.player_id, " ", GameManager.player_pos)
					#print("Received data: " + received_data)

func send_position():
	var position_data = {
		"id" : GameManager.player_id,
		"xpos" : GameManager.player_pos.x,
		"ypos" : GameManager.player_pos.y,
	}
	var json = JSON.new()
	var json_string = json.stringify(position_data) + "\n"
	socket.put_data(json_string.to_utf8_buffer())

func _exit_tree():
	socket.disconnect_from_host()

func load_platform_data(parsed_data):
	#print("Received platform data: ", parsed_data)

	# Load data into GameManager arrays
	if parsed_data.has("Platforms"):
		GameManager.platform_pos = parsed_data["Platforms"]
	if parsed_data.has("BreakingPlatforms"):
		GameManager.platform_break_pos = parsed_data["BreakingPlatforms"]
	if parsed_data.has("MovingPlatforms"):
		GameManager.platform_moving_pos = parsed_data["MovingPlatforms"]

	print("Platform data loaded successfully!")
	
func string_to_vector2(input: String) -> Vector2:
	var parts = input.split(" ")
	var x = float(parts[1])
	var y = float(parts[2])
	return Vector2(x, y)

func get_id_0(input: String) -> int:
	var parts = input.split(" ")
	return int(parts[0])
