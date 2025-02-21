extends Area2D

@onready var timer = $ChangeScreenTimer

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		# here send message aws saying this player won
		#print("you win")
		timer.start()
	pass

func _on_change_screen_timer_timeout() -> void:
	get_tree().change_scene_to_file("res://scenes/win_screen.tscn")
	pass
