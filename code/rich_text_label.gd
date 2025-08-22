extends RichTextLabel


# Customize these values:
var float_amplitude = 15      # How much it moves up and down (pixels)
var float_speed = 0.9            # Oscillation speed (Hz, like cycles per second)

var original_position = Vector2()

func _ready():
	original_position = position

func _process(delta):
	var time = Time.get_ticks_msec() / 1000.0
	position.y = original_position.y + sin(time * TAU * float_speed) * float_amplitude
