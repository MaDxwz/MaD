extends Control

@onready var image_display: TextureRect = $TextureRect
@onready var voice_player = $AudioStreamPlayer2D
@onready var level = preload("res://nodes/mainscene.tscn") # replace with your next scene

# Assign images directly here
var images = [
	preload("res://assests/backgrounds/6/1755786205220.png"),
	preload("res://assests/backgrounds/6/1755786205216.png"),
	preload("res://assests/backgrounds/6/1755786205211.png"),
	preload("res://assests/backgrounds/6/1755786205224.png"),
	preload("res://assests/backgrounds/6/1755786205202.png"),
	preload("res://assests/backgrounds/6/1755786205207.png")
]

# Times (in seconds) when each image should appear
var scene_times = [0, 15, 30, 40, 50, 62]

var current_index = 0

func _ready():
	show_scene1(0)
	await Fade.fade_out()
	
	# Assign and play your one long voice file
	voice_player.stream = preload("res://assests/others/ElevenLabs_2025-08-21T14_38_40_Lucius -  Deep voice_pvc_sp99_s70_sb60_se0_b_m2.mp3")
	voice_player.play()
	voice_player.finished.connect(_on_voice_finished)
	start_cutscene()


func start_cutscene() -> void:
	for i in range(1, images.size()):
		var wait_time = scene_times[i] - scene_times[i - 1]
		await get_tree().create_timer(wait_time).timeout
		show_scene(i)
		


func _process(delta):
	var t = voice_player.get_playback_position()
	if current_index < scene_times.size() - 1 and t >= scene_times[current_index + 1]:
		current_index += 1
		show_scene(current_index)

func show_scene(index: int):
	await Fade.fade_in()
	Fade.fade_long()
	if images.size() > index:
		image_display.texture = images[index]

func show_scene1(index: int):
	Fade.fade_long()
	if images.size() > index:
		image_display.texture = images[index]




func _on_voice_finished():
	# Fade out then change scene
	await Fade.fade_in()
	get_tree().change_scene_to_packed(level)
