extends ParallaxBackground

@onready var Fade2 = get_node("fade2")
@onready var next_scene

var scroll_speed: Vector2 = Vector2(50, 0)  # Background scroll speed (pixels/sec)

func _ready() -> void:
	if next_scene == null:
		next_scene = preload("res://nodes/cutscene.tscn")

func _process(delta):
	# Scroll the background
	scroll_offset += scroll_speed * delta

func _on_button_pressed() -> void:
	Fade2.fade_in1()
	await Fade.fade_in()
	get_tree().change_scene_to_packed(next_scene)
	await Fade.fade_out()

func _on_quit_pressed() -> void:
	Fade2.fade_in1()
	await Fade.fade_in()
	get_tree().quit()
