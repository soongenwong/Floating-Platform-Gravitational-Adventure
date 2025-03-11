extends Control

func _ready():
	GameManager.is_ready = false
	GameManager.other_ready = false
	GameManager.player_id = 0
	pass

func _on_player_1_pressed() -> void:
	GameManager.player_id = 1
	GameManager.is_ready = true
	ready_game()

func _on_player_2_pressed() -> void:
	GameManager.is_ready = true
	GameManager.player_id = 2
	ready_game()
	
	
func ready_game():
	get_tree().change_scene_to_file("res://scenes/wait_screen.tscn")


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/win_screen.tscn")
