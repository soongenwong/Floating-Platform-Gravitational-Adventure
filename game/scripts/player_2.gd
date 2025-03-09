extends CharacterBody2D


const SPEED = 130.0
const JUMP_VELOCITY = -500.0


func _physics_process(delta: float) -> void:
	global_position = GameManager.other_player_pos
	# Ensure velocity is zeroed out so move_and_slide doesn't interfere
	velocity = Vector2.ZERO
	move_and_slide()
