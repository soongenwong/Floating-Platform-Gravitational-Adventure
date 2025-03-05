extends Node2D

@export var platform_scene: PackedScene
@export var platform_break_scene: PackedScene
@export var platform_moving_scene: PackedScene
@export var coin_scene: PackedScene
@export var spawn_count: int = 290
@export var spawn_break_count: int = 160
@export var spawn_moving_count: int = 120
@export var spawn_range_x: Vector2 = Vector2(-150, 150)
@export var spawn_range_y: Vector2 = Vector2(-6000, 0)

func _ready():
	if (GameManager.player == 1):
		spawn_platforms()
		spawn_break()
		spawn_moving()
	else:
		for pos in GameManager.platform_pos:
			var platform = platform_scene.instantiate()
			platform.position = pos
			add_child(platform)
		for pos in GameManager.platform_break_pos:
			var platform_break = platform_break_scene.instantiate()
			platform_break.position = pos
			add_child(platform_break)
		for pos in GameManager.platform_moving_pos:
			var platform_moving = platform_moving_scene.instantiate()
			platform_moving.position = pos
			add_child(platform_moving)
	spawn_coin()

func spawn_platforms():
	for i in range(spawn_count):
		var platform = platform_scene.instantiate()
		platform.position = get_pos(i, spawn_count)
		GameManager.platform_pos.append(platform.position)
		add_child(platform)

func spawn_break():
	for i in range(spawn_break_count):
		var platform_break = platform_break_scene.instantiate()
		platform_break.position = get_pos_special(i, spawn_break_count)
		GameManager.platform_break_pos.append(platform_break.position)
		add_child(platform_break)
		
func spawn_moving():
	for i in range(spawn_moving_count):
		var platform_moving = platform_moving_scene.instantiate()
		platform_moving.position = get_pos_special(i, spawn_moving_count)
		GameManager.platform_moving_pos.append(platform_moving.position)
		add_child(platform_moving)
		var animation = platform_moving.get_node("AnimationPlayer")
		var length = animation.get_animation("move").length
		animation.seek(randf_range(0, length), true)

func spawn_coin():
	var coin = coin_scene.instantiate()
	coin.position = Vector2(0, spawn_range_y.x)
	add_child(coin)
	
func get_pos(num, count):
	return Vector2(randf_range(spawn_range_x.x, spawn_range_x.y), spawn_range_y.x/count * num)

func get_pos_special(num, count):
	return Vector2(randf_range(spawn_range_x.x, spawn_range_x.y), (spawn_range_y.x+200)/count * num -200)
