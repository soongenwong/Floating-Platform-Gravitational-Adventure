extends Area2D

@onready var timer = $ChangeScreenTimer
	
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		# here send message aws saying this player won
		#print("Player 1 wins")
		Global.winner_text = "Player 1 wins:\nTime - "  + str(GameManager.score) 
		timer.start()
	pass
	
	if body.is_in_group("Player_2"):
		#print("Player 2 wins")
		Global.winner_text = "Player 2 wins:\nTime - " + str(GameManager.score)
		timer.start()
	pass

func _on_change_screen_timer_timeout() -> void:
	get_tree().change_scene_to_file("res://scenes/win_screen.tscn")
	pass
