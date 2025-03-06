extends Node2D

@export var platform_scene: PackedScene
@export var platform_break_scene: PackedScene
@export var platform_moving_scene: PackedScene
@export var coin_scene: PackedScene

func _ready():
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
		var animation = platform_moving.get_node("AnimationPlayer")
		var length = animation.get_animation("move").length
		animation.seek(randf_range(0, length), true)
	spawn_coin()

func spawn_coin():
	var coin = coin_scene.instantiate()
	coin.position = Vector2(0, GameManager.spawn_range_y.x)
	add_child(coin)
