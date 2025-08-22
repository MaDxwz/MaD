extends Control

# Nodes
@onready var text_label = $RichTextLabel
@onready var text_timer = $Timer
@onready var image_display: TextureRect = $TextureRect
@onready var voice_player = $AudioStreamPlayer2D
@onready var level = preload("res://nodes/mainscene.tscn")

# Story text for each scene
var story_texts = [
	"In the stillness of dusk, a man in a tattered red cloak walked away from the village. His face was hidden, only two pale white eyes glowing faintly from under his hood. He carried no lantern, no weapon—just silence.",
	"From the shadows, a small orb of light drifted toward him. It shimmered like a firefly, but brighter, alive with strange intent. The man stopped, his hidden gaze narrowing. The orb pulsed once, as if asking him to follow... ",
	"Into the forest they went. The deeper he walked, the darker the trees grew, until the orb's glow was the only guide.Then it hovered before an old oak and burned letters into its bark:  ",
	"RUN. The man's cloak stirred. He turned back toward the village.",
	"Orange fire bled into the sky. Screams rode on the wind. The village was burning. He ran The orb rushed ahead, leading him through the forest until the trees broke, revealing a clearing",
	". There, in the earth, yawned a massive hole—unnatural, as if clawed open by something from below. The orb floated above it, waiting. Its glow flickered like a heartbeat. The man in the red cloak stood at the edge, smoke and fire at his back, the abyss before him. His eyes glowed brighter. The orb descended into the darkness, and without hesitation—he followed."
]

# Images for each scene
var images = [
	preload("res://assests/backgrounds/6/1755786205220.png"),
	preload("res://assests/backgrounds/6/1755786205216.png"),
	preload("res://assests/backgrounds/6/1755786205211.png"),
	preload("res://assests/backgrounds/6/1755786205224.png"),
	preload("res://assests/backgrounds/6/1755786205202.png"),
	preload("res://assests/backgrounds/6/1755786205207.png")
]

# Scene times in seconds
var scene_times = [0, 13, 30, 42, 50, 62]

# Typewriter variables
var char_index = 0
var full_text = ""
var words = []
var word_index = 0
var displayed_text = ""
var fade_tween: Tween

func _ready():
	text_label.text = ""
	# Enable word wrapping and rich text
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.bbcode_enabled = true
	
	# Timer setup
	text_timer.wait_time = 0.04  # Made slower
	text_timer.timeout.connect(_on_text_timeout)
	text_timer.one_shot = false
	
	# Show first scene
	show_scene1(0)
	await Fade.fade_out()
	
	# Play voice
	voice_player.stream = preload("res://assests/others/ElevenLabs_2025-08-21T14_38_40_Lucius -  Deep voice_pvc_sp99_s70_sb60_se0_b_m2.mp3")
	voice_player.play()
	voice_player.finished.connect(_on_voice_finished)
	
	# Start cutscene
	start_cutscene()

func start_cutscene() -> void:
	# Show first text immediately
	show_text(0)
	
	# Schedule remaining scenes
	for i in range(1, images.size()):
		var wait_time = scene_times[i] - scene_times[i - 1]
		await get_tree().create_timer(wait_time).timeout
		show_scene(i)
		# Text will appear after the long fade completes

func show_scene(index: int):
	# Fade out current text during the first fade
	
	
	await Fade.fade_in()
	fade_out_text()
	# Change image before starting long fade
	if images.size() > index:
		image_display.texture = images[index]
	show_text(index)
	await Fade.fade_long()  # Wait for long fade to completely finish
	
	# Start text only after long fade is done
	

func show_scene1(index: int):
	Fade.fade_long()
	if images.size() > index:
		image_display.texture = images[index]

func show_text(index: int):
	if story_texts.size() > index:
		start_text(story_texts[index])

func fade_out_text():
	# Fade out current text without blocking
	if text_label.text != "" and text_label.modulate.a > 0:
		if fade_tween:
			fade_tween.kill()
		fade_tween = create_tween()
		fade_tween.tween_property(text_label, "modulate:a", 0.0, 0.4)

func start_text(new_text: String):
	# Stop any existing timer
	text_timer.stop()
	if fade_tween:
		fade_tween.kill()
	
	# Setup new text immediately (no blocking fade out)
	full_text = new_text
	words = full_text.split(" ")
	char_index = 0
	word_index = 0
	displayed_text = ""
	text_label.text = ""
	text_label.modulate.a = 1.0
	text_timer.start()

func _on_text_timeout():
	if word_index < words.size():
		var current_word = words[word_index]
		
		if char_index < current_word.length():
			# Add character with fade in effect
			var new_char = current_word[char_index]
			displayed_text += new_char
			
			# Create fade in effect for the new character
			var char_pos = displayed_text.length() - 1
			var before_char = displayed_text.substr(0, char_pos)
			var after_char = displayed_text.substr(char_pos + 1)
			
			# Use BBCode to make the new character fade in
			text_label.text = before_char + "[color=#ffffff00]" + new_char + "[/color]" + after_char
			
			# Fade in the new character
			fade_tween = create_tween()
			fade_tween.tween_method(_fade_in_character, 0.0, 1.0, 0.3)  # Made slower (was 0.15)
			
			char_index += 1
		else:
			# Finished current word, add space and move to next word
			if word_index < words.size() - 1:
				displayed_text += " "
				text_label.text = displayed_text
			word_index += 1
			char_index = 0
	else:
		# Finished all text
		text_timer.stop()

func _fade_in_character(alpha: float):
	var char_pos = displayed_text.length() - 1
	if char_pos >= 0:
		var before_char = displayed_text.substr(0, char_pos)
		var current_char = displayed_text[char_pos]
		var after_char = displayed_text.substr(char_pos + 1)
		
		var alpha_hex = "%02x" % int(alpha * 255)
		text_label.text = before_char + "[color=#ffffff" + alpha_hex + "]" + current_char + "[/color]" + after_char

func _on_voice_finished():
	# Fade out then change scene
	await Fade.fade_in()
	get_tree().change_scene_to_packed(level)
