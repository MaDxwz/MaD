extends Camera2D

@onready var player := get_parent()

var offset_ground := Vector2(0, -80)
var offset_jump := Vector2(0, 0)

func _process(delta):
	if player.jumping:
		offset = offset_jump
	else:
		offset = offset_ground
