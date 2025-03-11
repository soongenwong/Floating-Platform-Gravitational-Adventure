extends Node2D

func _ready() -> void:
	GameManager.is_ready = false
	GameManager.other_ready = false
	GameManager.player_id = 0
