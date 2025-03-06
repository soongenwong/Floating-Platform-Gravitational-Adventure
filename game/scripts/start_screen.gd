extends Control

func _ready():
	GameManager.platform_pos = []
	GameManager.platform_moving_pos = []
	GameManager.platform_break_pos = []

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		ready_game()
		pass

func _on_start_button_pressed() -> void:
	ready_game()
	pass

func ready_game():
	get_tree().change_scene_to_file("res://scenes/wait_screen.tscn")


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/win_screen.tscn")
