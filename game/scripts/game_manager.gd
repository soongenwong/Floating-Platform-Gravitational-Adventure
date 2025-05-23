extends Node

var score: int = 0
var score_label: Label = null
 # player number
var player_id: int = 0
var other_id: int = 0
var other_ready: bool = false # are all other players ready
var is_ready: bool = 0
var player_pos: Vector2
var other_player_pos: Vector2 = Vector2(919, 575)
# platform positions
var platform_pos = [] # Table: Platforms
var platform_break_pos = [] # Table: BreakingPlatforms
var platform_moving_pos = [] # Table: MovingPlatforms
var platforms_loaded: bool = false
var spawn_count: int = 290
var spawn_break_count: int = 70
var spawn_moving_count: int = 30
var spawn_range_x: Vector2 = Vector2(-120, 120)
var spawn_range_y: Vector2 = Vector2(-4000, 0)
# References to scenes
#var scoreboard_scene = preload("res://scoreboard.tscn")
var current_scoreboard = null

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	#print("my pos: ", player_pos)
	#print("other pos: ", other_player_pos)
	pass

func update_score(new_score):
	score = new_score
	if score_label:
		score_label.text = str(score)
