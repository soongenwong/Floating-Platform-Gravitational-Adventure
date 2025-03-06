extends Node

var score: int = 0
var score_label: Label = null

var player: int = 1 # player number
var other_ready: bool = 1 # are all other players ready
var is_ready: bool = 0

# platform positions
var platform_pos = []
var platform_break_pos = []
var platform_moving_pos = []

var spawn_count: int = 290
var spawn_break_count: int = 70
var spawn_moving_count: int = 20
var spawn_range_x: Vector2 = Vector2(-150, 150)
var spawn_range_y: Vector2 = Vector2(-6000, 0)

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func update_score(new_score):
	score = new_score
	if score_label:
		score_label.text = str(score)
