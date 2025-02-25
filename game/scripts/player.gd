extends CharacterBody2D


const SPEED = 130.0
const JUMP_VELOCITY = -500.0
const DASH = 1000

@onready var sprite: Sprite2D = $Sprite2D


# add inputs from fpga here (keep keyboard input tho)
# share position of player from here
func _physics_process(delta: float) -> void:

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("ui_left", "ui_right")
	if direction > 0:
		sprite.flip_h = 0
	elif direction < 0:
		sprite.flip_h = 1
		
		
	if Input.is_action_just_pressed("dash"):
		if direction:
			velocity.x = direction * DASH
		else:
			velocity.x = direction * DASH
	elif direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
