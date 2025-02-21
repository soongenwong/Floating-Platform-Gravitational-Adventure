extends AnimatableBody2D



func _on_area_2d_body_entered(body):
	#print("on platform")
	$Timer.start(0.5)
	



func _on_timer_timeout():
	queue_free()
