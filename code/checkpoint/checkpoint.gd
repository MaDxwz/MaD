extends Node2D

@onready var light_effect = $Area2D/effect
@onready var start = $Area2D/CollisionShape2D
@onready var light = $PointLight2D
var camera: Camera2D
var original_zoom: Vector2 = Vector2(2, 2)
var target_zoom: Vector2 = Vector2(1.5, 1.5)  # Final zoom out level
var zoom_in_duration: float = 2.0  # Time to zoom back in smoothly

# Original light (after camera) - unchanged
var light_timer = 1.5
var is_light = false
var light_start = 0.0

# New light_effect synchronized with ripple - STRONG BLUE RING
var light_effect_timer: float = 4.5  # Total duration to match ripple effect
var is_light_effect: bool = false
var light_effect_start: float = 0.0
var max_light_effect_energy: float = 5.0  # Strong brightness for ring effect
var light_effect_fade_start_time: float = 2.3  # When to start fading
var light_effect_ring_lights: Array = []  # Array to hold multiple small lights forming a ring
var ring_light_count: int = 32  # Number of small lights to form the ring

# Teleport zoom levels (from high to low zoom)
var teleport_zoom_levels: Array = [Vector2(2.0, 2.0), Vector2(1.3, 1.3), Vector2(0.8, 0.8)]
var teleport_delays: Array = [0.0, 1.0, 2.0]  # Delay between each teleport step (1 second intervals)
var hold_duration: float = 2.0  # Time to hold at final zoom before smooth return

# Zoom control variables
var is_zooming: bool = false
var zoom_timer: float = 0.0
var zoom_phase: int = 0  # 0 = not zooming, 1 = teleporting, 2 = holding, 3 = zooming in
var current_teleport_step: int = 0
var first = false

# TileMap fade settings
var tilemap_layer: TileMapLayer
var tilemap_fade_duration: float = 1.5  # Duration of the fade effect
var is_tilemap_fading: bool = false
var tilemap_fade_timer: float = 0.0

func _ready():
	find_camera()
	find_tilemap_layer()
	create_ring_lights()  # Create the ring of lights

func find_camera():
	camera = get_viewport().get_camera_2d()
	if not camera:
		var cameras = get_tree().get_nodes_in_group("camera")
		if cameras.size() > 0:
			camera = cameras[0]
	if not camera:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			camera = player.find_child("Camera2D", true, false)
	if camera:
		original_zoom = camera.zoom
		teleport_zoom_levels[0] = original_zoom

func create_ring_lights():
	"""Create multiple small lights arranged in a ring pattern"""
	# Clear existing ring lights
	for light_node in light_effect_ring_lights:
		if light_node and is_instance_valid(light_node):
			light_node.queue_free()
	light_effect_ring_lights.clear()
	
	# Create ring of small lights
	for i in range(ring_light_count):
		var angle = (float(i) / float(ring_light_count)) * TAU
		var ring_light = PointLight2D.new()
		ring_light.color = Color(0.2, 0.4, 1.0, 1.0)  # Strong blue
		ring_light.energy = 0.0
		ring_light.texture_scale = 2.0  # Smaller lights
		
		add_child(ring_light)
		light_effect_ring_lights.append(ring_light)

func update_ring_light_positions(radius: float):
	"""Update positions of ring lights to match current ripple radius"""
	for i in range(light_effect_ring_lights.size()):
		var angle = (float(i) / float(ring_light_count)) * TAU
		var ring_light = light_effect_ring_lights[i]
		if ring_light and is_instance_valid(ring_light):
			var offset_from_center = start.get_parent().global_position - global_position
			ring_light.position = Vector2(cos(angle), sin(angle)) * radius + offset_from_center

func create_ripple_effect():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var ripple = Node2D.new()
	ripple.set_script(load("res://code/RippleEffect.gd"))
	get_tree().current_scene.add_child(ripple)
	ripple.global_position = start.get_parent().global_position
	ripple.max_radius = 2000.0
	ripple.ripple_speed = 200.0
	ripple.effect_color = Color(0.4, 0.7, 1.0, 1.0)
	ripple.play_effect()

func start_camera_zoom():
	if not camera or is_zooming:
		return
	is_zooming = true
	zoom_timer = 0.0
	zoom_phase = 1
	current_teleport_step = 0

func start_tilemap_fade():
	if not tilemap_layer:
		return
	is_tilemap_fading = true
	tilemap_fade_timer = 0.0

func find_tilemap_layer():
	tilemap_layer = $"../TileMapLayer2"
	if tilemap_layer:
		tilemap_layer.modulate.a = 0.0
		tilemap_layer.visible = true

func start_light_effect_with_ripple():
	"""Start ring light effect synchronized with ripple"""
	is_light_effect = true
	light_effect_start = 0.0

func start_light_fade():
	"""Original light fade function - unchanged"""
	if not light:
		return
	is_light = true
	light_start = 0.0
	light.energy = 0.0

func _process(delta):
	if not camera:
		return
	if is_light:
		update_light_fade(delta)  # Original light
	if is_light_effect:
		update_light_effect_with_ripple(delta)  # New light_effect
	if is_tilemap_fading:
		update_tilemap_fade(delta)
	if not is_zooming:
		return
	zoom_timer += delta
	match zoom_phase:
		1:
			if current_teleport_step < teleport_zoom_levels.size():
				if zoom_timer >= teleport_delays[current_teleport_step]:
					camera.zoom = teleport_zoom_levels[current_teleport_step]
					current_teleport_step += 1
			if current_teleport_step >= teleport_zoom_levels.size():
				zoom_phase = 2
				zoom_timer = 0.0
		2:
			if zoom_timer >= hold_duration:
				zoom_phase = 3
				zoom_timer = 0.0
		3:
			if zoom_timer <= zoom_in_duration:
				var progress = zoom_timer / zoom_in_duration
				progress = ease_in_out(progress)
				var current_zoom = teleport_zoom_levels[teleport_zoom_levels.size() - 1]
				camera.zoom = current_zoom.lerp(original_zoom, progress)
			else:
				camera.zoom = original_zoom
				is_zooming = false
				zoom_phase = 0
				zoom_timer = 0.0
				current_teleport_step = 0
				start_tilemap_fade()
				start_light_fade()  # Original light starts after camera

func update_tilemap_fade(delta):
	if not tilemap_layer:
		return
	tilemap_fade_timer += delta
	if tilemap_fade_timer <= tilemap_fade_duration:
		var progress = tilemap_fade_timer / tilemap_fade_duration
		progress = ease_in_out(progress)
		tilemap_layer.modulate.a = progress
	else:
		tilemap_layer.modulate.a = 1.0
		is_tilemap_fading = false

func update_light_fade(delta):
	"""Original light fade function - unchanged"""
	if not light:
		return
	light_start += delta
	if light_start <= light_timer:
		var progress = light_start / light_timer
		progress = ease_in_out(progress)
		light.energy = progress * 5.0  # 1.0 is max brightness for original light
	else:
		light.energy = 5.0
		is_light = false

func update_light_effect_with_ripple(delta):
	"""Update ring light effect to match ripple timing - STRONG BLUE RING"""
	if light_effect_ring_lights.is_empty():
		return
	
	light_effect_start += delta
	var current_energy = 0.0
	var current_radius = 0.0
	
	if light_effect_start <= light_effect_timer:
		# Calculate current ripple radius (matching the ripple script logic)
		var growing_timer = light_effect_start
		var speed_multiplier = 1.0
		var ripple_speed = 200.0  # Match your ripple speed
		
		if growing_timer < 1.8:  # Growing phase
			speed_multiplier = 1.0
		elif growing_timer < 2.3:  # Transition phase
			var transition_progress = (growing_timer - 1.8) / 0.5
			speed_multiplier = lerp(1.0, 3.0, transition_progress)
		else:  # Normal phase
			speed_multiplier = 7.0
		
		# Calculate radius (simplified version of ripple calculation)
		current_radius = ripple_speed * light_effect_start * (speed_multiplier * 0.5)  # Scale down for light ring
		
		# Phase 1: Growing phase (0-1.8s) - Light grows to STRONG peak
		if light_effect_start <= 1.8:
			var grow_progress = light_effect_start / 1.8
			grow_progress = ease_out(grow_progress)
			current_energy = grow_progress * max_light_effect_energy
		
		# Phase 2: Transition phase (1.8-2.3s) - Hold at STRONG peak with intense pulse
		elif light_effect_start <= light_effect_fade_start_time:
			var pulse_time = (light_effect_start - 1.8) * 8.0
			var pulse_intensity = 1.0 + sin(pulse_time) * 0.3  # 30% pulse variation
			current_energy = max_light_effect_energy * pulse_intensity
		
		# Phase 3: Fade phase (2.3s onwards) - Fade out with ripple
		else:
			var fade_progress = (light_effect_start - light_effect_fade_start_time) / (light_effect_timer - light_effect_fade_start_time)
			fade_progress = clamp(fade_progress, 0.0, 1.0)
			var fade_curve = 1.0 - pow(1.0 - fade_progress, 2.0)
			current_energy = max_light_effect_energy * (1.0 - fade_curve)
		
		# Update ring light positions and energy
		update_ring_light_positions(current_radius)
		
		# Set energy for all ring lights
		for ring_light in light_effect_ring_lights:
			if ring_light and is_instance_valid(ring_light):
				ring_light.energy = current_energy
	else:
		# Effect complete - turn off all ring lights
		for ring_light in light_effect_ring_lights:
			if ring_light and is_instance_valid(ring_light):
				ring_light.energy = 0.0
		is_light_effect = false

func ease_in_out(t: float) -> float:
	if t < 0.5:
		return 2.0 * t * t
	else:
		return -1.0 + (4.0 - 2.0 * t) * t

func ease_out(t: float) -> float:
	return 1.0 - pow(1.0 - t, 3.0)

func ease_in(t: float) -> float:
	return t * t * t

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and first == false:
		create_ripple_effect()
		start_light_effect_with_ripple()  # Start light_effect immediately with ripple
		start_camera_zoom()
		first = true

func reset_camera_zoom():
	if camera:
		camera.zoom = original_zoom
	is_zooming = false
	zoom_phase = 0
	zoom_timer = 0.0
	current_teleport_step = 0
	if tilemap_layer:
		tilemap_layer.modulate.a = 0.0
	is_tilemap_fading = false
	tilemap_fade_timer = 0.0
	# Reset both light effects
	if light:
		light.energy = 0.0
	is_light = false
	light_start = 0.0
	
	# Reset ring lights
	for ring_light in light_effect_ring_lights:
		if ring_light and is_instance_valid(ring_light):
			ring_light.energy = 0.0
	is_light_effect = false
	light_effect_start = 0.0

func set_teleport_zoom_parameters(zoom_levels: Array, delays: Array, hold_time: float, smooth_return_time: float):
	teleport_zoom_levels = zoom_levels
	teleport_delays = delays
	hold_duration = hold_time
	zoom_in_duration = smooth_return_time

func set_tilemap_fade_duration(fade_time: float):
	tilemap_fade_duration = fade_time

func set_tilemap_layer(tilemap: TileMapLayer):
	tilemap_layer = $"../BG/TileMapLayer2"
	if tilemap_layer:
		tilemap_layer.modulate.a = 0.0
		tilemap_layer.visible = true

func setup_custom_teleport_sequence():
	var custom_levels = [Vector2(2.0, 2.0), Vector2(1.3, 1.3), Vector2(0.8, 0.8)]
	var custom_delays = [0.0, 1.0, 2.0]
	set_teleport_zoom_parameters(custom_levels, custom_delays, 1.5, 2.0)
