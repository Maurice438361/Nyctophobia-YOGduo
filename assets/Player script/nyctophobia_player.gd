extends CharacterBody2D


@export var SPEED : int = 150
@export var GRAVITY : int = 900
@export var JUMP_FORCE : int = 300
@export var WALL_CLING_TIME : float = 0.2
@export var WALL_JUMP_FORCE : int = 200
@export var WALL_PUSH_FORCE : int = 300
@export var WALL_JUMP_GRACE : float = 0.2
@export var CLIMBING_SPEED : int = 100
@export var GRASS_JUMP_SFX : AudioStream
@export var WOOD_JUMP_SFX : AudioStream
@export var ROCK_JUMP_SFX : AudioStream
@export var DIRT_JUMP_SFX : AudioStream
@export var GRASS_FOOTSTEP_SFX : AudioStream
@export var WOOD_FOOTSTEP_SFX : AudioStream
@export var ROCK_FOOTSEP_SFX : AudioStream
@export var DIRT_FOOTSEP_SFX : AudioStream
@export var WALL_JUMP_SFX : AudioStream
@export var GRASS_LANDING_SFX : AudioStream
@export var WOOD_LANDING_SFX : AudioStream
@export var ROCK_LANDING_SFX : AudioStream
@export var DIRT_LANDING_SFX : AudioStream
@export var GRASS_LEDGE_PULL_SFX : AudioStream
@export var WOOD_LEDGE_PULL_SFX : AudioStream
@export var CLIMBING_SFX : AudioStream

var WallCling: bool = false
var WallClingRest: bool = false
var CantWalk: bool = false
var HangingFromWall: bool = false
var LedgeGrabRest: bool = false
var Climbing: bool = false
var IsInClimbleArea: bool = false
var InAir: bool = true
var Falling: bool = true

var FootStepFrames: Array = [4,9]
var VineGrabFrames: Array = [0,2]

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var wall_check_top = $TopCollisionChecker
@onready var wall_check_bottom = $BottomCollisionChecker
@onready var ledge_check = $LedgeCollisionChecker
@onready var jump_scum = $JumpCheat
@onready var player_sfx = $Player_sfx
@onready var ground_ray = $AnimatedSprite2D/GroundRay
@onready var ledge_ray_right = $AnimatedSprite2D/LedgeRayRight
@onready var ledge_ray_left = $AnimatedSprite2D/LedgeRayLeft

func is_touching_wall_full_side() -> bool:
	var top_overlapping = wall_check_top.has_overlapping_bodies()
	var bottom_overlapping = wall_check_bottom.has_overlapping_bodies()
	return top_overlapping and bottom_overlapping
	
func is_touching_ledge_side() -> bool:
	var wall_side_touched = wall_check_top.has_overlapping_bodies()
	var ledge_clear = !ledge_check.has_overlapping_bodies()
	return wall_side_touched and ledge_clear
	
func can_jump() -> bool:
	var is_on_floor = jump_scum.has_overlapping_bodies()
	return is_on_floor

func is_pushing_against_wall(v: Vector2) -> bool:
	return (Vector2(floor(v.x), floor(v.y)) == Vector2(1.0, 0.0) and Input.is_action_pressed("Left")) or \
		   (Vector2(floor(v.x), floor(v.y)) == Vector2(-1.0, 0.0) and Input.is_action_pressed("Right"))
		
func play_anim(name: String) -> void:
	if animated_sprite_2d.animation != name:
		animated_sprite_2d.play(name)
		
func set_climbing_area_overlap(value: bool) -> void:
	IsInClimbleArea = value

func load_sfx(sfx) :
	player_sfx.pitch_scale = randf_range(0.8, 1.2)
	if player_sfx.stream != sfx:
		player_sfx.stop()
		player_sfx.stream = sfx

func _physics_process(delta):
	
	#Run
	
	var direction = Input.get_axis("Left", "Right")
	
	if direction and !CantWalk: 
		
		velocity.x = direction * SPEED
		
		if is_on_floor():
			play_anim("Run")
			
		elif velocity:
			Falling = true
			
			
	elif !CantWalk: 
		
		velocity.x = 0
		
		if is_on_floor():
			play_anim("Idle")
	
	#Rotate
	
	if !HangingFromWall:
		if direction == 1:
			animated_sprite_2d.flip_h = false
		elif direction == -1:
			animated_sprite_2d.flip_h = true
	
	#Gravity
	
	if !is_on_floor() and !WallCling and !HangingFromWall and !Climbing:
		
		velocity.y += GRAVITY * delta
	
	#Jump
	
	if Input.is_action_just_pressed("Jump") and !InAir and !WallCling and !HangingFromWall and can_jump():
		
		velocity.y -= JUMP_FORCE
		InAir = true
		
		play_anim("Jump") 
		if ground_ray.is_colliding():
			var collider = ground_ray.get_collider()
			if collider.is_in_group("Grass"):
				load_sfx(GRASS_JUMP_SFX)
				player_sfx.play()
			elif collider.is_in_group("Tree"):
				load_sfx(WOOD_JUMP_SFX)
				player_sfx.play()
			elif collider.is_in_group("Rock"):
				load_sfx(ROCK_JUMP_SFX)
				player_sfx.play()
			else:
				load_sfx(DIRT_JUMP_SFX)
				player_sfx.play()
		
	#Fall
	
	if InAir and velocity.y > 0 or Falling and velocity.y > 0:
		play_anim("Fall")
	
	#land
	if InAir and is_on_floor() and velocity.y == 0:
		InAir = false
		Falling = false
		
		play_anim("Jump_land")
		
		if ground_ray.is_colliding():
			var collider = ground_ray.get_collider()
			if collider.is_in_group("Grass"):
				load_sfx(GRASS_LANDING_SFX)
				player_sfx.play()
			elif collider.is_in_group("Tree"):
				load_sfx(WOOD_LANDING_SFX)
				player_sfx.play()
			elif collider.is_in_group("Rock"):
				load_sfx(ROCK_LANDING_SFX)
				player_sfx.play()
			else:
					load_sfx(DIRT_LANDING_SFX)
					player_sfx.play()
	
	#LedgeGrab
	
	if !is_on_floor() and velocity.y > 0 and is_touching_ledge_side() and !LedgeGrabRest:
		var wallCollisionSide = get_wall_normal()
		if is_pushing_against_wall(wallCollisionSide):
			LedgeGrabRest = true
			CantWalk = true
			velocity.y = 0
			velocity.x = 0
			HangingFromWall = true
			play_anim("Climb_idle")
			if ledge_ray_right.is_colliding():
				var collider = ledge_ray_right.get_collider()
				if collider.is_in_group("Grass"):
					load_sfx(GRASS_LEDGE_PULL_SFX)
					player_sfx.play()
				elif collider.is_in_group("Tree"):
					load_sfx(WOOD_LEDGE_PULL_SFX)
					player_sfx.play()
			elif ledge_ray_left.is_colliding():
				var collider = ledge_ray_left.get_collider()
				if collider.is_in_group("Grass"):
					load_sfx(GRASS_LEDGE_PULL_SFX)
					player_sfx.play()
				elif collider.is_in_group("Tree"):
					load_sfx(WOOD_LEDGE_PULL_SFX)
					player_sfx.play()

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
			play_anim("Ledge_pull")
			if ledge_ray_right.is_colliding():
				var collider = ledge_ray_right.get_collider()
				if collider.is_in_group("Grass"):
					load_sfx(GRASS_LEDGE_PULL_SFX)
					player_sfx.play()
				elif collider.is_in_group("Tree"):
					load_sfx(WOOD_LEDGE_PULL_SFX)
					player_sfx.play()
			elif ledge_ray_left.is_colliding():
				var collider = ledge_ray_left.get_collider()
				if collider.is_in_group("Grass"):
					load_sfx(GRASS_LEDGE_PULL_SFX)
					player_sfx.play()
				elif collider.is_in_group("Tree"):
					load_sfx(WOOD_LEDGE_PULL_SFX)
					player_sfx.play()
			InAir = true
	
	#WallJump
	
	if !is_on_floor() and !WallClingRest and velocity.y > 0 and is_touching_wall_full_side():
		var wallCollisionSide = get_wall_normal()
		if is_pushing_against_wall(wallCollisionSide):
			WallCling = true
			WallClingRest = true
			velocity.y = 0
			play_anim("Climb_idle")
			await get_tree().create_timer(WALL_CLING_TIME).timeout
			WallCling = false
			InAir = true
			play_anim("Ledge_pull")
			
	
	if WallClingRest:
		if is_on_floor():
			WallClingRest = false
		
		if !is_on_wall():
			WallCling = false
	
	if WallCling:
		var wallCollisionSide = get_wall_normal()
		if  !is_pushing_against_wall(wallCollisionSide):
			WallCling = false
			InAir = true
			play_anim("Ledge_pull")
		
		if Input.is_action_just_pressed("Jump"):
			WallCling = false
			CantWalk = true
			velocity.y -= WALL_JUMP_FORCE
			velocity.x = get_wall_normal().x * WALL_PUSH_FORCE
			play_anim("Ledge_pull")
			load_sfx(WALL_JUMP_SFX)
			player_sfx.play()
			InAir = true
			await get_tree().create_timer(WALL_JUMP_GRACE).timeout
			CantWalk = false
	
	#WallClimb
	
	if IsInClimbleArea and Input.is_action_just_pressed("Up"):
		Climbing = true
		velocity.y = 0
		
	if Climbing:
		InAir = false
		
		if Input.is_action_just_pressed("Up"):
			velocity.y -= CLIMBING_SPEED
			play_anim("Climb")
			
		if Input.is_action_just_pressed("Down"):
			velocity.y += CLIMBING_SPEED 
			play_anim("Climb")
			
		if !Input.is_action_pressed("Up") and !Input.is_action_pressed("Down"):
			velocity.y = 0
			play_anim("Climb_idle")
			
		if !IsInClimbleArea or Input.is_action_just_pressed("Jump"):
			Climbing = false
			InAir = true
		
	move_and_slide()


func _on_sprite_frame_changed():
	if(animated_sprite_2d.animation == "Run"):
		if ground_ray.is_colliding():
			if animated_sprite_2d.frame in FootStepFrames:
				var collider = ground_ray.get_collider()
				if collider.is_in_group("Grass"):
					load_sfx(GRASS_FOOTSTEP_SFX)
					player_sfx.play()
				elif collider.is_in_group("Tree"):
					load_sfx(WOOD_FOOTSTEP_SFX)
					player_sfx.play()
				elif collider.is_in_group("Rock"):
					load_sfx(ROCK_FOOTSEP_SFX)
					player_sfx.play()
				else:
					load_sfx(DIRT_FOOTSEP_SFX)
					player_sfx.play()
	if(animated_sprite_2d.animation == "Climb"):
		if animated_sprite_2d.frame in VineGrabFrames:
			load_sfx(CLIMBING_SFX)
			player_sfx.play()
