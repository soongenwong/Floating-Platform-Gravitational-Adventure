extends Control

func _ready():
	GameManager.platform_pos = []
	GameManager.platform_moving_pos = []
	GameManager.platform_break_pos = []

func _on_player_1_pressed() -> void:
	GameManager.player == 1
	ready_game()

func ready_game():
	get_tree().change_scene_to_file("res://scenes/wait_screen.tscn")


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/win_screen.tscn")
