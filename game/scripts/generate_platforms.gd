extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if (GameManager.player == 1):
		spawn_platforms()
		spawn_break()
		spawn_moving()


func spawn_platforms():
	for i in range(GameManager.spawn_count):
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


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")
