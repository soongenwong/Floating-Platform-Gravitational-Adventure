extends AnimatableBody2D

func _on_area_2d_body_entered(body):
	#print("on platform")
	if body is CharacterBody2D:
		if body.velocity.y == 0:
			$Timer.start(0.3)

func _on_timer_timeout():
	queue_free()
