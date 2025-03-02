extends Control

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		start_game()
		pass

func _on_restart_button_pressed() -> void:
	start_game()
	pass

func start_game():
	#print("going to start screen")
	GameManager.score = 0
	get_tree().change_scene_to_file("res://scenes/start_screen.tscn")
