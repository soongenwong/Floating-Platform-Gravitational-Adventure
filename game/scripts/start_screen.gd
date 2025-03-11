extends Control

func _ready():
	pass

func _on_player_1_pressed() -> void:
	GameManager.player = 1
	GameManager.player_id = 1
	GameManager.is_ready = true
	ready_game()

func _on_player_2_pressed() -> void:
	GameManager.player = 2
	GameManager.is_ready = true
	# this is to check which project im on.
	# another check.
	GameManager.player_id = 2
	ready_game()
	
	
func ready_game():
	get_tree().change_scene_to_file("res://scenes/wait_screen.tscn")


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/win_screen.tscn")
