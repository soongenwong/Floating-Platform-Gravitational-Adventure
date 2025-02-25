extends Node

var score: int = 0
var score_label: Label = null

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func update_score(new_score):
	score = new_score
	if score_label:
		score_label.text = "Score: " + str(score)
