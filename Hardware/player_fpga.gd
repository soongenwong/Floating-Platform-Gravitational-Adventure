extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 980.0

# Create UDP server
var udp = PacketPeerUDP.new()
var server_port = 9000

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	setup_udp_server()

func setup_udp_server() -> void:
	# Create and bind UDP socket
	var err = udp.bind(server_port)
	if err != OK:
		print("Error binding to port ", server_port, ": ", err)
		return
	
	print("UDP server listening on port ", server_port)

func _process(delta: float) -> void:
	if udp.get_available_packet_count() > 0:
		var packet_data = udp.get_packet()
		var sender_address = udp.get_packet_ip()
		var sender_port = udp.get_packet_port()
		
		var classification = packet_data.get_string_from_utf8()
		print("Received classification: ", classification, " from ", sender_address, ":", sender_port)
		
		process_classification(classification)
	
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	move_and_slide()

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

func _exit_tree() -> void:
	udp.close()