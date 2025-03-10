extends CharacterBody2D

func _process(delta: float) -> void:
	position = GameManager.other_player_pos
