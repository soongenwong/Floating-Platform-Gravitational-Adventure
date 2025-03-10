extends CharacterBody2D

const SPEED_FAST = 130.0
const SPEED_MEDIUM = 100.0
const SPEED_STILL = 0.0
const DASH_MULTIPLIER = 1.8
const JUMP_VELOCITY = -400.0
const GRAVITY = 980.0

# Create UDP server
var udp = PacketPeerUDP.new()
var server_port = 9000

# Movement state tracking
var current_direction = "centre"
var current_speed = "still"
var is_dashing = false
var is_jumping = false
var direction_change_time = 0.0
var movement_timeout = 0.0
var smooth_factor = 0.1
var dash_cooldown = 0.0
var dash_duration = 0.0
var can_dash = true

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

func _physics_process(delta: float) -> void:
	# Check for incoming UDP packets
	if udp.get_available_packet_count() > 0:
		var packet_data = udp.get_packet()
		var sender_address = udp.get_packet_ip()
		var sender_port = udp.get_packet_port()
		
		# Convert the packet data to a string
		var new_classification = packet_data.get_string_from_utf8()
		print("Received classification: ", new_classification, " from ", sender_address, ":", sender_port)
		
		# Extract movement data
		var parts = new_classification.split(" + ")
		if parts.size() == 4:
			current_direction = parts[0]
			current_speed = parts[1]
			is_dashing = parts[2] == "dashing"
			is_jumping = parts[3] == "jumping"
			
			# Reset timers when direction changes
			direction_change_time = 0.0
			movement_timeout = 0.0
			
			# Handle dash
			if is_dashing and can_dash:
				start_dash()
	
	# Update dash state
	update_dash_state(delta)
	
	# Process the current movement
	process_movement(delta)
	
	# Process jumping
	if is_jumping:
		jump()
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	# Execute the movement
	move_and_slide()

func start_dash():
	if can_dash:
		is_dashing = true
		dash_duration = 0.0
		can_dash = false
		dash_cooldown = 0.0

func update_dash_state(delta: float):
	# Update dash duration
	if is_dashing:
		dash_duration += delta
		if dash_duration > 0.3:  # Dash lasts 0.3 seconds
			is_dashing = false
	
	# Update dash cooldown
	if not can_dash:
		dash_cooldown += delta
		if dash_cooldown > 1.0:  # Can dash again after 1 second
			can_dash = true

func process_movement(delta: float) -> void:
	# Update timers
	direction_change_time += delta
	
	# Get base speed based on current_speed
	var base_speed = SPEED_STILL
	if current_speed == "fast":
		base_speed = SPEED_FAST
	elif current_speed == "medium":
		base_speed = SPEED_MEDIUM
	
	# Apply dash multiplier if dashing
	var actual_speed = base_speed
	if is_dashing:
		actual_speed *= DASH_MULTIPLIER
	
	# Process direction with persistence
	if current_direction == "left":
		sprite.flip_h = true
		# Smoothly accelerate to calculated speed
		velocity.x = lerp(velocity.x, -actual_speed, smooth_factor)
	elif current_direction == "right":
		sprite.flip_h = false
		# Smoothly accelerate to calculated speed
		velocity.x = lerp(velocity.x, actual_speed, smooth_factor)
	else:  # centre
		# Smoothly decelerate to stop
		velocity.x = lerp(velocity.x, 0.0, smooth_factor * 2)

func lerp(a: float, b: float, t: float) -> float:
	return a + (b - a) * t

func jump() -> void:
	if is_on_floor():
		velocity.y = JUMP_VELOCITY
		is_jumping = false  # Reset jump state after executing jump

func _exit_tree() -> void:
	# Clean up resources when the node is removed from the scene
	udp.close()
