extends Node2D

@onready var camera = $player/Camera2D
@onready var fade_player: AnimationPlayer = $ColorRect/AnimationPlayer
@onready var player = $player  # reference to CharacterBody2D
@onready var anim: AnimatedSprite2D = $player/AnimatedSprite2D

func _ready() -> void:
	player.animation_locked = true 
	fade_player.play("fade2")
	await zoom_camera(Vector2(4, 4), 0.1)  # zoom in over 0.5s
	anim.play("fell")
	
	await anim.animation_finished

	# --- Start zooming back to normal after fell ---
	zoom_camera(Vector2(2, 2), 5)  # zoom out over 0.5s

	anim.play("up")
	await anim.animation_finished
	anim.play("idle")
	fade_player.play("cutscene")
	await fade_player.animation_finished
	player.animation_locked = false

func zoom_camera(target_zoom: Vector2, duration: float) -> void:
	var start_zoom = camera.zoom
	var time_passed = 0.0
	while time_passed < duration:
		time_passed += get_process_delta_time()
		var t = time_passed / duration
		camera.zoom = start_zoom.lerp(target_zoom, t)  # ✅ use .lerp in Godot 4
		await get_tree().process_frame
	camera.zoom = target_zoom
