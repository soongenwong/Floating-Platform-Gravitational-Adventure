extends Node2D

@export var platform_scene: PackedScene
@export var spawn_count: int = 100
@export var spawn_range_x: Vector2 = Vector2(-100, 100)
@export var spawn_range_y: Vector2 = Vector2(-1000, 0)

func _ready():
	spawn_platforms()

func spawn_platforms():
	for i in range(spawn_count):
		var platform = platform_scene.instantiate()
		platform.position = Vector2(
			randf_range(spawn_range_x.x, spawn_range_x.y),
			randf_range(spawn_range_y.x, spawn_range_y.y)
		)
		add_child(platform)
