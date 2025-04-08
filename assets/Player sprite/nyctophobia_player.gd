extends CharacterBody2D


@export var SPEED : int = 150
@export var GRAVITY : int = 900
@export var JUMP_FORCE : int = 300
@export var WALL_CLING_TIME : float = 1
@export var WALL_JUMP_FORCE : int = 200
@export var WALL_PUSH_FORCE : int = 300
@export var WALL_JUMP_GRACE : float = 0.5

var WallCling = false
var WallClingRest = false
var WallJumped = false

func _physics_process(delta):
	
	#Run
	
	var direction = Input.get_axis("Left", "Right")
	
	if direction and !WallJumped: 
		
		velocity.x = direction * SPEED
		
		if is_on_floor():
			$AnimatedSprite2D.play("Run")
		
	elif !WallJumped: 
		
		velocity.x = 0
		
		if is_on_floor():
			$AnimatedSprite2D.play("Idle")
	
	#Rotate
	
	if direction == 1:
		$AnimatedSprite2D.flip_h = false
	elif direction == -1:
		$AnimatedSprite2D.flip_h = true
	
	#Gravity
	
	if !is_on_floor() and !WallCling:
		
		velocity.y += GRAVITY * delta
	
	#Jump
	
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		
		velocity.y -= JUMP_FORCE
		
		$AnimatedSprite2D.play("Jump")
	
	#WallJump
	
	if !is_on_floor() and is_on_wall() and !WallClingRest and velocity.y > 0:
		var wallCollisionSide = get_wall_normal()
		if wallCollisionSide == Vector2(1.0,0.0) and Input.is_action_pressed("Left") or wallCollisionSide == Vector2(-1.0,0.0) and Input.is_action_pressed("Right"):
			WallCling = true
			WallClingRest = true
			velocity.y = 0
			await get_tree().create_timer(WALL_CLING_TIME).timeout
			WallCling = false
			
	
	if is_on_floor() and WallClingRest:
		WallClingRest = false
		
	if !is_on_wall() and WallClingRest:
		WallCling = false
		
	if WallCling and Input.is_action_just_pressed("Jump"):
		WallCling = false
		WallJumped = true
		velocity.y -= WALL_JUMP_FORCE
		velocity.x = get_wall_normal().x * WALL_PUSH_FORCE
		await get_tree().create_timer(WALL_JUMP_GRACE).timeout
		WallJumped = false
		
	move_and_slide()
	
