extends ParallaxBackground

@onready var Fade2 = $fade2
@onready var next_scene
@onready var lightning_flash: ColorRect = $ColorRect # White overlay for flash effect
@onready var lightning_sound: AudioStreamPlayer2D = $lightning
@onready var thunder_sound: AudioStreamPlayer2D = $thunder

var scroll_speed: Vector2 = Vector2(50, 0)  # Background scroll speed

# Lightning and thunder timers
var lightning_timer: float = 0.0
var thunder_timer: float = 0.0

# Lightning intervals
var lightning_interval_min: float = 25.0
var lightning_interval_max: float = 40.0

# Thunder intervals
var thunder_interval_min: float = 35.0
var thunder_interval_max: float = 45.0

var next_lightning_time: float = 0.0
var next_thunder_time: float = 0.0

func _ready() -> void:
	if next_scene == null:
		next_scene = preload("res://nodes/animations/cutscene.tscn")

	setup_lightning_flash()
	schedule_next_lightning()
	schedule_next_thunder()


func setup_lightning_flash() -> void:
	if not lightning_flash:
		lightning_flash = ColorRect.new()
		add_child(lightning_flash)
		lightning_flash.name = "LightningFlash"

	lightning_flash.color = Color.WHITE
	lightning_flash.modulate.a = 0.0
	lightning_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lightning_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lightning_flash.z_index = 100


func _process(delta: float) -> void:
	# Scroll background
	scroll_offset += scroll_speed * delta

	# Lightning timer
	lightning_timer += delta
	if lightning_timer >= next_lightning_time:
		trigger_lightning()
		lightning_timer = 0.0
		schedule_next_lightning()

	# Thunder timer
	thunder_timer += delta
	if thunder_timer >= next_thunder_time:
		# Ensure thunder does not play at the same time as lightning
		if not lightning_sound.playing:
			if thunder_sound and thunder_sound.stream:
				thunder_sound.play()
		thunder_timer = 0.0
		schedule_next_thunder()


func schedule_next_lightning() -> void:
	next_lightning_time = randf_range(lightning_interval_min, lightning_interval_max)


func schedule_next_thunder() -> void:
	next_thunder_time = randf_range(thunder_interval_min, thunder_interval_max)


func trigger_lightning() -> void:
	# Flash sequence
	lightning_flash_sequence()

	# Lightning sound
	if lightning_sound and lightning_sound.stream:
		lightning_sound.play()


func lightning_flash_sequence() -> void:
	var flash_tween = create_tween()

	# First flash
	flash_tween.tween_property(lightning_flash, "modulate:a", 0.7, 0.05)
	flash_tween.tween_property(lightning_flash, "modulate:a", 0.0, 0.1)

	# Short interval
	flash_tween.tween_interval(0.08)

	# Second flash
	flash_tween.tween_property(lightning_flash, "modulate:a", 0.9, 0.03)
	flash_tween.tween_property(lightning_flash, "modulate:a", 0.3, 0.15)
	flash_tween.tween_property(lightning_flash, "modulate:a", 0.0, 0.2)

	# Optional triple flash
	if randf() < 0.2:
		flash_tween.tween_interval(0.05)
		flash_tween.tween_property(lightning_flash, "modulate:a", 0.6, 0.02)
		flash_tween.tween_property(lightning_flash, "modulate:a", 0.0, 0.12)


# Button pressed: transition to next scene
func _on_button_pressed() -> void:
	Fade2.fade_in1()
	await Fade.fade_in()
	get_tree().change_scene_to_packed(next_scene)
	await Fade.fade_out()


# Quit pressed
func _on_quit_pressed() -> void:
	Fade2.fade_in1()
	await Fade.fade_in()
	get_tree().quit()


# Manual trigger if needed
func force_lightning() -> void:
	trigger_lightning()


# Control lightning and thunder frequency dynamically
func set_lightning_frequency(min_interval: float, max_interval: float) -> void:
	lightning_interval_min = min_interval
	lightning_interval_max = max_interval


func set_thunder_frequency(min_interval: float, max_interval: float) -> void:
	thunder_interval_min = min_interval
	thunder_interval_max = max_interval
