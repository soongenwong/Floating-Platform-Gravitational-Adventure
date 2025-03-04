extends Label

var time_elapsed: float = 0.0

func _ready() -> void:
	GameManager.score_label = self
	
func _process(delta):
	time_elapsed += delta
	GameManager.update_score(time_elapsed)
