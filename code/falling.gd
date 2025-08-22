extends CharacterBody2D

@export var target_scene: String = "res://scenes/NextScene.tscn"
@export var orbit_min_radius := 100.0  # start small
@export var orbit_max_radius := 300.0  # max radius
@export var orbit_speed := 3.0
@export var radius_growth_speed := 100.0 # how fast radius grows per second

@export var gravity: float = 900.0
@export var terminal_velocity: float = 1500.0

var angle := 0.0
var current_radius := 100.0  # start at min radius

@onready var light_bulb = $light

# --- Surprise animation vars ---
var surprise_timer := 0.0
var surprise_state = 0  # 0=idle, 1=going up, 2=orbiting, 3=coming down
var orbiting = true
@export var surprise_up_height := 150.0
@export var surprise_orbit_radius := 150.0
@export var surprise_orbit_speed := 8.0
@export var surprise_duration := 2.0  # total surprise animation time

# Stop animation sequence vars
var stop_state := 0 # 0=idle, 1=spin, 2=drop
var stop_time := 0.0

func _physics_process(delta):
	velocity.y += gravity * delta
	velocity.y = clamp(velocity.y, -INF, terminal_velocity)

	velocity.x = sin(Time.get_ticks_msec() / 300.0) * 50

	move_and_slide()

func _process(delta):
	if orbiting and surprise_state == 0:
		# Normal orbit while falling
		if velocity.y > 1:
			current_radius = min(current_radius + radius_growth_speed * delta, orbit_max_radius)
			angle += orbit_speed * delta
			var offset = Vector2(cos(angle), sin(angle)) * current_radius
			light_bulb.position = offset
		else:
			current_radius = orbit_min_radius
			light_bulb.position = Vector2(0, -current_radius / 2)
	elif stop_state > 0:
		run_stop_sequence(delta)

func start_surprise():
	# Save world position
	var global_pos = light_bulb.global_position
	
	# Detach from player so it won't move with it
	light_bulb.get_parent().remove_child(light_bulb)
	get_tree().current_scene.add_child(light_bulb)
	
	# Keep the same world position
	light_bulb.global_position = global_pos
	
	# Start spinning state
	stop_state = 1
	stop_time = 0.0

func run_stop_sequence(delta):
	stop_time += delta
	match stop_state:
		1:
			# Spin in place for 0.5 seconds
			light_bulb.rotation += delta * 2 # faster spin
			if stop_time >= 3 :
				stop_state = 2
				stop_time = 0.0
		2:
			# Drop down really fast
			light_bulb.global_position.y += delta * 1500.0

func _on_light_anim_body_entered(_body):
	orbiting = false
	start_surprise()
	await Fade.fade_long3()
	get_tree().change_scene_to_file(target_scene)
