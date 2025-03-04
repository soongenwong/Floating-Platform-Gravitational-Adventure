extends Area2D

@onready var timer = $ChangeScreenTimer
@export var speed: float = 50

func _process(delta: float) -> void:
	position.y -= speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		#print("died skill issue :(")
		timer.start()
	else:
		body.queue_free()
		#print("body deleted")
	pass

func _on_change_screen_timer_timeout() -> void:
	#print("going to death screen")
	get_tree().change_scene_to_file("res://scenes/death_screen.tscn")
	pass
