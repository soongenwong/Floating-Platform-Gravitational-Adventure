extends Node2D

@export var platform_scene: PackedScene
@export var platform_break_scene: PackedScene
@export var coin_scene: PackedScene
@export var spawn_count: int = 100
@export var spawn_break_count: int = 50
@export var spawn_range_x: Vector2 = Vector2(-100, 100)
@export var spawn_range_y: Vector2 = Vector2(-1000, 0)

var platform_locations = []

func _ready():
	spawn_platforms()
	spawn_coin()
	
	# share platform_locations to aws
	

func spawn_platforms():
	for i in range(spawn_count):
		var platform = platform_scene.instantiate()
		platform.position = Vector2(
			randf_range(spawn_range_x.x, spawn_range_x.y),
			randf_range(spawn_range_y.x, spawn_range_y.y)
		)
		platform_locations.append(platform.position)
		
		add_child(platform)
	
	for i in range(spawn_count):
		var platform_break = platform_break_scene.instantiate()
		platform_break.position = Vector2(
			randf_range(spawn_range_x.x, spawn_range_x.y),
			randf_range(spawn_range_y.x, spawn_range_y.y)
		)
		platform_locations.append(platform_break.position)
		
		add_child(platform_break)

func spawn_coin():
	var coin = coin_scene.instantiate()
	coin.position = Vector2(0, spawn_range_y.x)
	add_child(coin)
