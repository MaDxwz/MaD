extends "res://code/charachter/mc.gd"

@onready var follower_light = $"../light"
@onready var light: PointLight2D = $"../light/PointLight2D"
@onready var light_sprite: Sprite2D = $"../light/Sprite2D"
@onready var player_light: PointLight2D = $"../light/PointLight2D2"

func _ready() -> void:
	light.energy = 0.0
	light_sprite.visible = true
	light_sprite.modulate.a = 0.0
	if player_light:
		player_light.energy = 0.0
	follower_light.global_position = global_position + offset
	

func _physics_process(delta: float) -> void:
	update_light_system(delta)

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
