extends Control

func _process(delta: float) -> void:
	if GameManager.is_ready and GameManager.other_id != 0:
		get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")
