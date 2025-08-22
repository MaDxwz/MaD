extends Node2D

# define fire colors
var fire_colors = [
	Color(1.0, 1.0, 0.6),  # hot center (yellow)
	Color(1.0, 0.7, 0.28), # main glow (orange-yellow)
	Color(1.0, 0.27, 0.0)  # outer edges (red-orange)
]

var current_color = Color(1,1,1)

func _ready():
	flicker_light()  # start flicker loop

func flicker_light():
	var light = $PointLight2D
	if light:
		# flicker intensity
		var flicker = randf_range(0.95, 1.05)
		light.energy = 1.0 * flicker

		# smooth color change
		var target_color = fire_colors[randi() % fire_colors.size()]
		current_color = current_color.lerp(target_color, 0.1)  # ✅ use .lerp in Godot 4
		light.color = current_color

	# call again after a short delay
	await get_tree().create_timer(0.05).timeout
	flicker_light()
