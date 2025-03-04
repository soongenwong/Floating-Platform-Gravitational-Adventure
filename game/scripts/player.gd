extends CharacterBody2D


const SPEED = 130.0
const JUMP_VELOCITY = -400.0
const DASH_SPEED = 400
const DASH_DURATION = 0.2
const DASH_COOLDOWN = 1

var dashing = false
var dash_timer = 0.0
var dash_cooldown = 0

var server := StreamPeerTCP.new()
var is_connected := false

const PORT = 12000

@onready var sprite: Sprite2D = $Sprite2D

# add inputs from fpga here (keep keyboard input tho)
# share position of player from here
func _physics_process(delta: float) -> void:
	if is_connected and server.get_available_bytes() > 0:
		var received_data = server.get_utf8_string(server.get_available_bytes())
		print("Received: ", received_data)

	if not is_on_floor(): 
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("ui_left", "ui_right")
	if direction > 0:
		sprite.flip_h = 0
	elif direction < 0:
		sprite.flip_h = 1

	if (Input.is_action_just_pressed("dash") && dashing == false && dash_cooldown <= 0):
		dashing = true
		dash_timer = DASH_DURATION

	if dashing:
		velocity.x = direction * DASH_SPEED
		dash_timer -= delta
		if dash_timer <= 0:
			dashing = false
			dash_cooldown = DASH_COOLDOWN
	elif direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	#if int(-position.y + 450 > GameManager.score):
	#	GameManager.update_score(-int(position.y) + 450)
	move_and_slide()
	dash_cooldown_time(delta)

func dash_cooldown_time(delta):
	if dash_cooldown > 0:
		dash_cooldown -= delta
