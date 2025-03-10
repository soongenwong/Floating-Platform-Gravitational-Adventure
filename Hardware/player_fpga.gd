extends CharacterBody2D

const SPEED_FAST = 90.0
const SPEED_MEDIUM = 70.0
const SPEED_STILL = 0.0
const DASH_SPEED = 400
const JUMP_VELOCITY = -400.0
const GRAVITY = 980.0

# Create UDP server
var udp = PacketPeerUDP.new()
var server_port = 9000

# Movement state tracking
var current_direction = "centre"
var current_speed = 0.0
var is_dashing = false
var is_jumping = false
var direction_change_time = 0.0
var movement_timeout = 0.0
var smooth_factor = 0.1
var dash_cooldown = 0.5
var dash_duration = 0.2
var can_dash = true

# Keyboard input flags
var keyboard_control = false
var keyboard_direction = "centre"
var keyboard_speed = "medium"  # Default keyboard speed

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	setup_udp_server()
	# Adding C key input action for dash
	if not InputMap.has_action("dash_c_key"):
		InputMap.add_action("dash_c_key")
		var c_key_event = InputEventKey.new()
		c_key_event.keycode = KEY_C
		InputMap.action_add_event("dash_c_key", c_key_event)

func setup_udp_server() -> void:
	# Create and bind UDP socket
	var err = udp.bind(server_port)
	if err != OK:
		print("Error binding to port ", server_port, ": ", err)
		return
	
	print("UDP server listening on port ", server_port)

func _physics_process(delta: float) -> void:
	# First check for keyboard input
	process_keyboard_input()
	
	# Then check for UDP packets (will override keyboard if received)
	process_udp_input()
	
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

func process_keyboard_input() -> void:
	# Check if any movement key is pressed
	var left_pressed = Input.is_action_pressed("ui_left")
	var right_pressed = Input.is_action_pressed("ui_right")
	var jump_pressed = Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_accept")
	var dash_pressed = Input.is_action_just_pressed("ui_focus_next") or Input.is_action_just_pressed("dash_c_key")  # Tab or C key for dash
	var sprint_pressed = Input.is_action_pressed("ui_select")  # Space key for sprint
	
	# Only use keyboard if a key is pressed
	if left_pressed or right_pressed or jump_pressed or dash_pressed or sprint_pressed:
		keyboard_control = true
		
		# Determine direction
		if left_pressed and right_pressed:
			keyboard_direction = "centre"
		elif left_pressed:
			keyboard_direction = "left"
		elif right_pressed:
			keyboard_direction = "right"
		else:
			keyboard_direction = "centre"
		
		# Determine speed
		if sprint_pressed:
			keyboard_speed = "fast"
		else:
			keyboard_speed = "medium"
		
		# Apply keyboard input to character state
		current_direction = keyboard_direction
		current_speed = keyboard_speed
		
		# Handle jumping
		if jump_pressed:
			is_jumping = true
		
		# Handle dashing
		if dash_pressed and can_dash:
			is_dashing = true
			start_dash()
	else:
		# If no keys are pressed, revert control method and set to still
		keyboard_control = false
		if current_direction == keyboard_direction:  # Only reset if keyboard was controlling
			current_direction = "centre"
			current_speed = "still"

func process_udp_input() -> void:
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
			# UDP input overrides keyboard input
			keyboard_control = false
			
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

func start_dash():
	if can_dash:
		is_dashing = true
		dash_duration = 0.2
		can_dash = false
		dash_cooldown = 0.5

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
	var actual_speed = float(current_speed)*5
	if is_dashing and current_direction == "left":
		velocity.x = -1 * DASH_SPEED
	elif is_dashing and current_direction == "right":
		velocity.x = DASH_SPEED
	
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
