extends CharacterBody2D


@export var SPEED : int = 150
@export var GRAVITY : int = 900
@export var JUMP_FORCE : int = 300



func _physics_process(delta):
	
	var direction = Input.get_axis("Left", "Right")
	
	if direction: 
		
		velocity.x = direction * SPEED
		
	else: 
		
		velocity.x = 0
	
	#Rotate
	
	if direction == 1:
		$Sprite2D.flip_h = false
	elif direction == -1:
		$Sprite2D.flip_h = true
	
	#Gravity
	
	if not is_on_floor():
		
		velocity.y += GRAVITY * delta
	
	#Jump
	
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		
		velocity.y -= JUMP_FORCE
	
	move_and_slide()
