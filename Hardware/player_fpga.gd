extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -400.0

var http_client: HTTPClient = HTTPClient.new()
var connected: bool = false
var request_in_progress: bool = false
var request_timer: float = 0.0

const SERVER_ADDRESS: String = "127.0.0.1"
const SERVER_PORT: int = 9000
const PATH: String = "/data"

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	connect_to_server()

# Create a new HTTPClient instance and connect.
func connect_to_server() -> void:
	http_client = HTTPClient.new()  # reinitialize for a fresh connection
	var err = http_client.connect_to_host(SERVER_ADDRESS, SERVER_PORT)
	if err == OK:
		print("Attempting to connect to server...")
	else:
		print("Failed to initiate connection: ", err)
	# connected flag will be set once STATUS_CONNECTED is reached

func _process(delta: float) -> void:
	# Poll HTTPClient every frame to update its state.
	http_client.poll()
	
	match http_client.get_status():
		HTTPClient.STATUS_CONNECTED:
			if not connected:
				connected = true
				print("Connected to server.")
		HTTPClient.STATUS_CONNECTION_ERROR:
			if connected:
				print("Connection error. Reconnecting...")
			connected = false
			connect_to_server()
		_:
			pass
	
	# Lower the request interval from 1.0 to 0.2 seconds.
	request_timer += delta
	if request_timer >= 0.1:
		request_timer = 0.0
		if connected and not request_in_progress:
			var err = http_client.request(HTTPClient.METHOD_GET, PATH, [])
			if err == OK:
				request_in_progress = true
				print("GET request sent")
			else:
				print("HTTP request error: ", err)
	
	# Process response if a GET request is in progress.
	if request_in_progress:
		http_client.poll()
		if http_client.get_status() == HTTPClient.STATUS_BODY and http_client.has_response():
			var response_text: String = ""
			# Read response chunks.
			while true:
				var chunk: PackedByteArray = http_client.read_response_body_chunk()
				if chunk.size() == 0:
					break
				response_text += chunk.get_string_from_utf8()
			request_in_progress = false
			var result: Dictionary = process_response(response_text)
			if result.has("classification"):
				var classification: String = result["classification"]
				print("Received classification: ", classification)
				process_classification(classification)
			# Reinitialize HTTPClient for the next request.
			http_client = HTTPClient.new()
			connected = false
			connect_to_server()
		else:
			http_client.poll()
	
	# Apply gravity (using only the y component).
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	
	move_and_slide()

# Parse JSON response.
func process_response(response_text: String) -> Dictionary:
	var json_parser = JSON.new()
	var err = json_parser.parse(response_text)
	if err != OK:
		print("JSON parse error: ", json_parser.get_error_message())
		return {}
	return json_parser.get_data()

# Map classification to game motion.
func process_classification(classification: String) -> void:
	if "left" in classification:
		move_left()
	elif "right" in classification:
		move_right()
	else:
		stop_movement()
	if "jump" in classification:
		jump()

func move_left() -> void:
	sprite.flip_h = true
	velocity.x = -SPEED

func move_right() -> void:
	sprite.flip_h = false
	velocity.x = SPEED

func stop_movement() -> void:
	velocity.x = 0

func jump() -> void:
	if is_on_floor():
		velocity.y = JUMP_VELOCITY
