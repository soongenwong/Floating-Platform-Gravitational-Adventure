extends Control

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		start_game()
		pass

func _on_start_button_pressed() -> void:
	start_game()
	pass

func start_game():
	#print("starting game")
	get_tree().change_scene_to_file("res://scenes/game.tscn")
	pass


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/win_screen.tscn")
