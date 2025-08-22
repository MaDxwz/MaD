extends CharacterBody2D


@onready var camera = $Camera2D
@onready var anim = $"../AnimationPlayer"
@export var target_scene: String = "res://scenes/NextScene.tscn"
@export var walk_speed := 100
@export var run_speed := 200
@export var acceleration := 1000.0
@export var friction := 800.0
@export var gravity := 1000.0
@export var min_jump_velocity := -100.0
@export var max_jump_velocity := -250.0
@export var max_hold_time := 0.25
@onready var player = $"."
var original_position: Vector2
var last_direction := Vector2.RIGHT
var is_jumping := false
var jump_time := 0.0
var returning = false
@onready var anim_sprite := $AnimatedSprite2D

var animation_locked: bool = false   # <--- NEW

func _ready() -> void:
	anim_sprite.play("idle")
	Fade.connect("fade_almost_finished", Callable(self, "on_fade_almost_finished"))
	original_position = camera.position
	animation_locked = true
	await Fade.fade_long4()


func _physics_process(delta):
	if returning:
		camera.position = camera.position.lerp(original_position, 3 * delta)
		if camera.position.distance_to(original_position) < 1:
			camera.position = original_position
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")

	var is_running = Input.is_action_pressed("run")
	var speed = run_speed if is_running else walk_speed

	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Jumping logic
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and animation_locked == false:
		velocity.y = min_jump_velocity
		is_jumping = true
		jump_time = 0.0

	if is_jumping and Input.is_action_pressed("ui_accept") and velocity.y < 0:
		if jump_time < max_hold_time:
			jump_time = min(jump_time + delta, max_hold_time)
			var hold_ratio = jump_time / max_hold_time
			velocity.y = lerp(min_jump_velocity, max_jump_velocity, hold_ratio)
		else:
			is_jumping = false

	if Input.is_action_just_released("ui_accept") or velocity.y >= 0:
		is_jumping = false

	# Horizontal movement
	if input_vector.x != 0 and animation_locked == false:
		velocity.x = move_toward(velocity.x, input_vector.x * speed, acceleration * delta)
		last_direction.x = input_vector.x
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	# ✅ Animations (only if not locked)
	if not animation_locked:
		if not is_on_floor():
			if velocity.y < 0:
				anim_sprite.play("jump")
			else:
				anim_sprite.play("fall")
		elif input_vector.x != 0:
			anim_sprite.play("run" if is_running else "walk")
		else:
			anim_sprite.play("idle")

	anim_sprite.flip_h = last_direction.x < 0

	move_and_slide()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == player:
		await Fade.fade_long2()
		get_tree().change_scene_to_file(target_scene)


func _on_area_2d_2_body_entered(body: Node2D) -> void:
	if body == player:
		anim_sprite.play("idle")
		animation_locked = true
		anim.play("down")
		await anim.animation_finished
		returning = true
		animation_locked = false

func on_fade_almost_finished():
	anim.play("follow")
	await anim.animation_finished
	animation_locked = false
