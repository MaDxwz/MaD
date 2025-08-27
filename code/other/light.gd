extends CharacterBody2D

@export var follow_speed := 8.0  # Higher = faster follow

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _process(delta):
	var target_pos = get_global_mouse_position()

	# Smooth movement using interpolation
	global_position = global_position.lerp(target_pos, follow_speed * delta)
