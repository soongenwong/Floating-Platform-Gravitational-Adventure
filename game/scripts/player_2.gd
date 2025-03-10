extends CharacterBody2D

func _process(delta: float) -> void:
	#print(GameManager.other_player_pos)
	position = GameManager.other_player_pos
	#position = GameManager.other_player_pos
	#print("player2physics: ", position)
