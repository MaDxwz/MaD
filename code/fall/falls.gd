extends Camera2D

@export var shake_strength: float = 0.0
@export var shake_decay: float = 0.5 # How quickly the shake fades
@export var shake_frequency: float = 25.0 # How fast it vibrates

var _shake_offset := Vector2.ZERO
var _noise := FastNoiseLite.new()
var _time_passed := 0.0
var _has_shaken := false

func _ready():
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 10.1

func _process(delta):
	zoom -= Vector2(0.15, 0.15) * delta
	zoom.x = clamp(zoom.x, 1.14, 2.5)
	zoom.y = clamp(zoom.y, 1.14, 2.5)

	if shake_strength > 0.01:
		_time_passed += delta * shake_frequency

		# Smooth offset
		_shake_offset.x = _noise.get_noise_2d(_time_passed, 0.0) * shake_strength
		_shake_offset.y = _noise.get_noise_2d(0.0, _time_passed) * shake_strength

		offset = _shake_offset

		# Fade out
		shake_strength = lerp(shake_strength, 0.0, delta * shake_decay)
	else:
		offset = Vector2.ZERO

func start_shake(strength: float):
	shake_strength = strength
	_time_passed = 0.0


func _on_area_2d_body_entered(_body):
	if not _has_shaken:
		start_shake(10.0) 
		_has_shaken = true
