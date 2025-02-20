extends Area2D

@onready var timer = $Timer

func _on_body_entered(body: Node2D) -> void:
	print("Died skill issue :(")
	timer.start()
	pass


func _on_timer_timeout() -> void:
	print("going to death screen")
	get_tree().change_scene_to_file("res://scenes/death_screen.tscn")
	pass
