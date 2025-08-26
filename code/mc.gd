extends CharacterBody2D

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player: Node = $"."  # reference to self

@onready var follower_light: Node2D = $"../light"
@onready var light: PointLight2D = $"../light/PointLight2D"
@onready var light_sprite: Sprite2D = $"../light/Sprite2D"
@onready var player_light: PointLight2D = $PointLight2D  # Child node for player light

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
	light.energy = 0.0
	light_sprite.visible = true
	light_sprite.modulate.a = 0.0
	if player_light:
		player_light.energy = 0.0
	follower_light.global_position = global_position + offset

func _physics_process(delta: float) -> void:
	handle_movement(delta)
	update_light_system(delta)

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

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # ESC key
		if light_state == "following":
			start_player_light_fade()  # Switch to player light
		elif light_state == "player_fading":
			start_follower_light()  # Switch back to follower light
		elif light_state == "none":
			start_follower_light()  # Start following if nothing active

func start_follower_light() -> void:
	light_state = "following"
	light_timer = 0.0
	light.energy = 0.0
	light_sprite.modulate.a = 0.0
	follower_velocity = Vector2.ZERO
	follower_light.global_position = global_position + offset

func start_player_light_fade() -> void:
	light_state = "player_fading"
	light_timer = 0.0

func update_light_system(delta: float) -> void:
	match light_state:
		"following":
			handle_light_following(delta)
		"player_fading":
			handle_light_fading(delta)

func handle_light_following(delta: float) -> void:
	var target_pos: Vector2 = global_position + offset
	var direction: Vector2 = (target_pos - follower_light.global_position)
	
	# Acceleration
	follower_velocity += direction * follow_acceleration * delta
	# Limit max speed
	if follower_velocity.length() > max_follow_speed:
		follower_velocity = follower_velocity.normalized() * max_follow_speed
	# Apply friction
	follower_velocity *= follow_friction

	# Update position
	follower_light.global_position += follower_velocity * delta

	# Fade in follower light
	if light.energy < max_energy:
		light.energy = min(light.energy + max_energy * delta / appear_time, max_energy)
	if light_sprite.modulate.a < 1.0:
		light_sprite.modulate.a = min(light_sprite.modulate.a + delta / appear_time, 1.0)

	# Fade out player light if active
	if player_light and player_light.energy > 0.0:
		player_light.energy = max(player_light.energy - max_energy * delta / fade_time, 0.0)

func handle_light_fading(delta: float) -> void:
	# Fade in player light
	if player_light:
		player_light.energy = min(player_light.energy + max_energy * delta / appear_time, max_energy)

	# Follower light still follows smoothly
	var target_pos: Vector2 = global_position + offset
	var direction: Vector2 = (target_pos - follower_light.global_position)
	follower_velocity += direction * follow_acceleration * delta
	if follower_velocity.length() > max_follow_speed:
		follower_velocity = follower_velocity.normalized() * max_follow_speed
	follower_velocity *= follow_friction
	follower_light.global_position += follower_velocity * delta

	# Fade out follower light
	if light.energy > 0.0:
		light.energy = max(light.energy - max_energy * delta / fade_time, 0.0)
	if light_sprite.modulate.a > 0.0:
		light_sprite.modulate.a = max(light_sprite.modulate.a - delta / fade_time, 0.0)
