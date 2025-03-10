extends CharacterBody2D


const SPEED = 130.0
const JUMP_VELOCITY = -500.0


func _process(delta: float) -> void:
	print(GameManager.other_player_pos)
	position = GameManager.other_player_pos
	#position = GameManager.other_player_pos
	print("player2physics: ", position)
