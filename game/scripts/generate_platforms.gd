extends Control

func _process(delta: float) -> void:
	if GameManager.is_ready and GameManager.other_id != 0:
		get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_button_pressed() -> void:
	spawn_platforms()
	spawn_break()
	spawn_moving()
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func spawn_platforms():
	for i in range(0, GameManager.spawn_count, 3):
		position = get_pos(i, GameManager.spawn_count)
		GameManager.platform_pos.append(position)
		position = get_pos(i, GameManager.spawn_count)
		GameManager.platform_pos.append(position)
		position = get_pos(i, GameManager.spawn_count)
		GameManager.platform_pos.append(position)
		 
func spawn_break():
	for i in range(GameManager.spawn_break_count):
		position = get_pos_special(i, GameManager.spawn_break_count)
		GameManager.platform_break_pos.append(position)

func spawn_moving():
	for i in range(GameManager.spawn_moving_count):
		position = get_pos_special(i, GameManager.spawn_moving_count)
		GameManager.platform_moving_pos.append(position)

func get_pos(num, count):
	return Vector2(randf_range(GameManager.spawn_range_x.x, GameManager.spawn_range_x.y), GameManager.spawn_range_y.x/count * num)

func get_pos_special(num, count):
	return Vector2(randf_range(GameManager.spawn_range_x.x, GameManager.spawn_range_x.y), (GameManager.spawn_range_y.x+500)/count * num -500)
