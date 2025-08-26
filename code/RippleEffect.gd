extends Node2D
var radius: float = 0.0
var max_radius: float = 500.0
var growing: bool = false
var width: float = 20.0
var ripple_speed: float = 600.0
var effect_color: Color = Color(0.3, 0.6, 1.0, 1.0)
var alpha: float = 1.0
var fade_speed: float = 0.3

# Animation effects - THIS IS THE GROWING EFFECT
var pulse_time: float = 0.0
var scale_effect: float = 1.0

# Timer control for growing effect
var growing_timer: float = 0.0
var growing_duration: float = 1.8  # Duration in seconds for growing effect
var use_growing_effect: bool = false
var transition_duration: float = 0.5  # Smooth transition time
var speed_multiplier: float = 10.0  # Speed control for normal phase

# New subtle enhancements
var shimmer_time: float = 0.0
var core_glow_intensity: float = 1.0

func play_effect():
	# Reset everything
	radius = 0.0
	alpha = 1.0
	pulse_time = 0.0
	scale_effect = 1.0
	growing_timer = 0.0
	speed_multiplier = 10.0
	use_growing_effect = true  # Start with growing effect
	growing = true
	visible = true
	
	# Reset new effects
	shimmer_time = 0.0
	core_glow_intensity = 1.0

func _process(delta):
	if not growing:
		return
	
	# Update growing timer
	growing_timer += delta
	
	# Update shimmer effect
	shimmer_time += delta * 4.0
	
	# Smooth transition logic
	if growing_timer < growing_duration:
		# Still in growing phase
		use_growing_effect = true
		speed_multiplier = 1.0
		core_glow_intensity = 1.2  # Slightly brighter during initial phase
	elif growing_timer < growing_duration + transition_duration:
		# Transition phase - smooth change
		var transition_progress = (growing_timer - growing_duration) / transition_duration
		use_growing_effect = true
		speed_multiplier = lerp(1.0, 3.0, transition_progress)  # Speed up to 3x
		
		# Gradually reduce the growing effect intensity
		var growing_intensity = lerp(0.15, 0.0, transition_progress)
		pulse_time += delta * 8.0
		scale_effect = 1.0 + sin(pulse_time) * growing_intensity
		
		# Fade core glow intensity during transition
		core_glow_intensity = lerp(1.2, 0.8, transition_progress)
	else:
		# Normal phase - fast growth, no pulsing
		use_growing_effect = false
		speed_multiplier = 7.0  # 3x faster
		scale_effect = 1.0
		core_glow_intensity = 0.6  # Dimmer in final phase
	
	# Grow radius with speed multiplier
	radius += ripple_speed * delta * speed_multiplier
	
	# Fade out with slight easing
	var fade_curve = 1.0 - pow(1.0 - (growing_timer / (growing_duration + transition_duration + 2.0)), 2.0)
	alpha = max(0.0, 1.0 - fade_curve)
	
	# Growing effect only during growing phase
	if use_growing_effect and growing_timer < growing_duration:
		pulse_time += delta * 8.0
		scale_effect = 1.0 + sin(pulse_time) * 0.15
	elif growing_timer < growing_duration + transition_duration:
		pass # Transition handled above
	
	# End effect
	if alpha <= 0 or radius > max_radius:
		growing = false
		visible = false
		queue_free()
	
	queue_redraw()

func _draw():
	if not growing or radius <= 0 or alpha <= 0:
		return
	
	var current_color = effect_color
	current_color.a = alpha
	
	# Extended outer glow layers (fades faster than the main ring)
	var glow_alpha = alpha * alpha  # Square alpha for faster fade
	for glow_layer in range(8, 0, -1):
		var glow_radius: float
		
		# Use growing effect while timer is active
		if use_growing_effect:
			var animated_radius = radius * scale_effect
			glow_radius = animated_radius + glow_layer * 8
		else:
			glow_radius = radius + glow_layer * 8
		
		# Add subtle shimmer to outer layers
		var shimmer_offset = sin(shimmer_time + glow_layer * 0.8) * 1.5
		glow_radius += shimmer_offset
		
		var glow_color = current_color
		glow_color.a = glow_alpha * 0.2 / glow_layer
		
		if glow_radius > 0:
			draw_circle(Vector2.ZERO, glow_radius, glow_color)
	
	# Main ring only
	var main_radius: float
	
	# Use growing effect while timer is active
	if use_growing_effect:
		main_radius = radius * scale_effect
	else:
		main_radius = radius
	
	if main_radius > 0:
		# Main ring (hollow)
		draw_arc(Vector2.ZERO, main_radius, 0, TAU, 128, current_color, width)
		
		# Bright edge with saubtle shimmer (hollow)
		var edge_brightness = 0.9 + sin(shimmer_time * 2.0) * 0.1
		var edge_color = Color.WHITE
		edge_color.a = alpha * edge_brightness
		draw_arc(Vector2.ZERO, main_radius + width/4, 0, TAU, 128, edge_color, width * 0.25)

# Optional: Function to reset the effect (if you want to allow it again later)
func reset_effect():
	growing_timer = 0.0
	speed_multiplier = 1.0
	use_growing_effect = true
	shimmer_time = 0.0
	core_glow_intensity = 1.0

	
