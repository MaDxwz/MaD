extends CharacterBody2D

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player: Node = $"."  # reference to self

# Movement parameters
@export var walk_speed: float = 80.0
@export var run_speed: float = 160.0
@export var acceleration: float = 800.0
@export var air_acceleration: float = 600.0
@export var friction: float = 700.0
@export var air_friction: float = 300.0
@export var gravity: float = 800.0
@export var fall_gravity: float = 1200.0
@export var max_fall_speed: float = 400.0

# Jump parameters
@export var jump_velocity: float = -160.0
@export var max_jump_hold_time: float = 0.25
@export var jump_cut_multiplier: float = 0.5
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.1

# State variables
var last_direction: Vector2 = Vector2.RIGHT
var is_jumping: bool = false
var jump_time: float = 0.0
var animation_locked: bool = false
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var was_on_floor: bool = false

# Light system variables
var light_state: String = "none"  # "following", "player_fading", "none"
var light_timer: float = 0.0
var follower_velocity: Vector2 = Vector2.ZERO  # For smooth acceleration

# Light parameters
var max_energy: float = 5.0
var appear_time: float = 2.0
var fade_time: float = 2.0
var offset: Vector2 = Vector2(40, -60)  # Offset from player
var follow_acceleration: float = 6.0  # acceleration multiplier
var follow_friction: float = 0.9      # velocity damping for smoothness
var max_follow_speed: float = 600.0   # max speed for follower

func _ready() -> void:
	add_to_group("player")
	floor_max_angle = deg_to_rad(45)
	floor_snap_length = 8.0
	
	# Initialize lights


func _physics_process(delta: float) -> void:
	handle_movement(delta)

func handle_movement(delta: float) -> void:
	var input_vector: Vector2 = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var is_running: bool = Input.is_action_pressed("run")
	var target_speed: float = run_speed if is_running else walk_speed

	if input_vector.x != 0:
		last_direction.x = input_vector.x

	var current_accel: float = acceleration if is_on_floor() else air_acceleration
	var current_friction: float = friction if is_on_floor() else air_friction

	if input_vector.x != 0:
		velocity.x = move_toward(velocity.x, input_vector.x * target_speed, current_accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, current_friction * delta)

	if not is_on_floor():
		var current_grav: float = fall_gravity if velocity.y > 0 else gravity
		velocity.y += current_grav * delta
		if velocity.y > max_fall_speed:
			velocity.y = max_fall_speed

	# Jumping
	if jump_buffer_timer > 0 and coyote_timer > 0 and not animation_locked:
		velocity.y = jump_velocity
		is_jumping = true
		jump_time = 0.0
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

	if is_jumping and Input.is_action_pressed("ui_accept") and velocity.y < 0:
		if jump_time < max_jump_hold_time:
			jump_time += delta
			velocity.y = min(velocity.y, lerp(jump_velocity, jump_velocity * 1.8, jump_time / max_jump_hold_time))
		else:
			is_jumping = false

	if Input.is_action_just_released("ui_accept") and velocity.y < 0:
		velocity.y *= jump_cut_multiplier
		is_jumping = false

	if velocity.y >= 0:
		is_jumping = false

	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta

	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta

	# Animations
	if not animation_locked:
		if not is_on_floor():
			anim_sprite.play("jump" if velocity.y < 0 else "fall")
		elif abs(velocity.x) > 10:
			anim_sprite.play("run" if is_running else "walk")
		else:
			anim_sprite.play("idle")
		anim_sprite.flip_h = last_direction.x < 0

	move_and_slide()
