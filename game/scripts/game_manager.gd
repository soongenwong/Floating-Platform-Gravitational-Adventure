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

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func update_score(new_score):
	score = new_score
	if score_label:
		score_label.text = "Score: " + str(score)
