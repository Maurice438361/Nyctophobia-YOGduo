extends AudioStreamPlayer2D

var time = 0.5

func _on_finished():
	await get_tree().create_timer(time).timeout
	self.play()
