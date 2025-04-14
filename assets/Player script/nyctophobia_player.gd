extends CharacterBody2D


@export var SPEED : int = 150
@export var GRAVITY : int = 900
@export var JUMP_FORCE : int = 300
@export var WALL_CLING_TIME : float = 0.2
@export var WALL_JUMP_FORCE : int = 200
@export var WALL_PUSH_FORCE : int = 300
@export var WALL_JUMP_GRACE : float = 0.2

var WallCling = false
var WallClingRest = false
var CantWalk = false
var HangingFromWall = false
var LedgeGrabRest = false

@onready var wall_check_top = $TopCollisionChecker
@onready var wall_check_bottom = $BottomCollisionChecker
@onready var ledge_check = $LedgeCollisionChecker

func is_touching_wall_full_side() -> bool:
	var top_overlapping = wall_check_top.has_overlapping_bodies()
	var bottom_overlapping = wall_check_bottom.has_overlapping_bodies()
	return top_overlapping and bottom_overlapping
	
func is_touching_ledge_side() -> bool:
	var wall_side_touched = wall_check_top.has_overlapping_bodies()
	var ledge_clear = !ledge_check.has_overlapping_bodies()
	return wall_side_touched and ledge_clear

func is_pushing_against_wall(normal: Vector2) -> bool:
	return (normal == Vector2(1.0, 0.0) and Input.is_action_pressed("Left")) or \
		   (normal == Vector2(-1.0, 0.0) and Input.is_action_pressed("Right"))
		
func play_anim(name: String) -> void:
	if $AnimatedSprite2D.animation != name:
		$AnimatedSprite2D.play(name)

func _physics_process(delta):
	
	#Run
	
	var direction = Input.get_axis("Left", "Right")
	
	if direction and !CantWalk: 
		
		velocity.x = direction * SPEED
		
		if is_on_floor():
			play_anim("Run")
		
	elif !CantWalk: 
		
		velocity.x = 0
		
		if is_on_floor():
			play_anim("Idle")
	
	#Rotate
	
	if direction == 1:
		$AnimatedSprite2D.flip_h = false
	elif direction == -1:
		$AnimatedSprite2D.flip_h = true
	
	#Gravity
	
	if !is_on_floor() and !WallCling and !HangingFromWall:
		
		velocity.y += GRAVITY * delta
	
	#Jump
	
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		
		velocity.y -= JUMP_FORCE
		
		play_anim("Jump")
	
	#LedgeGrab
	
	if !is_on_floor() and velocity.y > 0 and is_touching_ledge_side() and !LedgeGrabRest:
		LedgeGrabRest = true
		CantWalk = true
		velocity.y = 0
		HangingFromWall = true
	
	if LedgeGrabRest and !is_touching_ledge_side() or LedgeGrabRest and is_on_floor():
		LedgeGrabRest = false
	
	if HangingFromWall:
		var wallCollisionSide = get_wall_normal()
		if Input.is_action_pressed("Down") or wallCollisionSide == Vector2(1.0,0.0) and Input.is_action_pressed("Right") or wallCollisionSide == Vector2(-1.0,0.0) and Input.is_action_pressed("Left"):
			CantWalk = false
			HangingFromWall = false
		
		if Input.is_action_pressed("Up") or Input.is_action_just_pressed("Jump"):
			CantWalk = false
			HangingFromWall = false
			velocity.y -= 300
	
	#WallJump
	
	if !is_on_floor() and !WallClingRest and velocity.y > 0 and is_touching_wall_full_side():
		var wallCollisionSide = get_wall_normal()
		if is_pushing_against_wall(wallCollisionSide):
			WallCling = true
			WallClingRest = true
			velocity.y = 0
			await get_tree().create_timer(WALL_CLING_TIME).timeout
			WallCling = false
			
	
	if WallClingRest:
		if is_on_floor():
			WallClingRest = false
		
		if !is_on_wall():
			WallCling = false
	
	if WallCling:
		var wallCollisionSide = get_wall_normal()
		if  !is_pushing_against_wall(wallCollisionSide):
			WallCling = false
		
		if Input.is_action_just_pressed("Jump"):
			WallCling = false
			CantWalk = true
			velocity.y -= WALL_JUMP_FORCE
			velocity.x = get_wall_normal().x * WALL_PUSH_FORCE
			await get_tree().create_timer(WALL_JUMP_GRACE).timeout
			CantWalk = false
		
	move_and_slide()
