extends AudioStreamPlayer2D

func _ready():
	playRandomSound()

func playRandomSound():
	while true:
		var time = randf_range(5.0, 15.0)
		await get_tree().create_timer(time).timeout
		self.pitch_scale = randf_range(0.8, 1.2)
		self.play()
