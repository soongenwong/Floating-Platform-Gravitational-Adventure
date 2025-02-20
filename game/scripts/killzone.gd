extends Area2D

@onready var timer = $Timer

func _on_body_entered(body: Node2D) -> void:
	print("Died")
	timer.start()
	pass


func _on_timer_timeout() -> void:
	get_tree().change_scene_to_file("res://scenes/start_screen.tscn")
	print("goto start scene")
	pass
