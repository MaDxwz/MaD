extends Control

@onready var image_display: TextureRect = $TextureRect
@onready var text_bar: TextureRect = $ColorRect/TextureRect
@onready var rich_text: RichTextLabel = $ColorRect/TextureRect/RichTextLabel
@onready var voice_player: AudioStreamPlayer2D = $narrator
@onready var effect1 = $effect1
@onready var effect2 = $effect2
@onready var music = $music
@export var text_speed: float = 0.07
@export var shake_intensity: float = 5.0
@export var shake_duration: float = 0.3

# Original positions for shake effect
var original_image_pos: Vector2
var original_text_pos: Vector2

# Separate arrays for different content types
var cutscene = [
	{"image":"res://assests/backgrounds/6/1755786205220.png", "text":"In the stillness of dusk... a man, in a tattered red cloak, walked away from the village. His face—hidden. Only two pale, white eyes... glowing faintly beneath the hood. He carried no lantern , no weapon , nothing at all—only silence..."},
	{"image":"res://assests/backgrounds/6/1755786205216.png", "text":"Second scene appears here."},
	{"image":"res://assests/backgrounds/6/1755786205211.png", "text":"Third scene is shown now."},
	{"image":"res://assests/backgrounds/6/1755786205224.png", "text":"Fourth line of dialogue."},
	{"image":"res://assests/backgrounds/6/1755786205202.png", "text":"Fifth scene text."},
	{"image":"res://assests/backgrounds/6/1755786205207.png", "text":"Last scene, goodbye!"}
]

# Preloaded voice resources
var voices = [
	preload("res://assests/others/voice/ElevenLabs_2025-08-25T20_31_28_Lucius -  Deep voice_pvc_sp90_s70_sb50_se10_b_m2.mp3"),
	#preload("res://assests/others/voice/voice2.mp3"),
	#preload("res://assests/others/voice/voice3.mp3"),
	#preload("res://assests/others/voice/voice4.mp3"),
	#preload("res://assests/others/voice/voice5.mp3"),
	#preload("res://assests/others/voice/voice6.mp3")
]

var played_voices := {}

func _ready() -> void:
	rich_text.bbcode_enabled = true
	# Store original positions for shake effect
	original_image_pos = image_display.position
	original_text_pos = text_bar.position
	start_cutscene()

func start_cutscene() -> void:
	# Start background music with fade-in
	start_background_music()
	
	for i in range(cutscene.size()):
		var step = cutscene[i]
		
		# Set image
		var image_resource = load(step["image"])
		if image_resource:
			image_display.texture = image_resource
		else:
			print("Failed to load image: ", step["image"])
		
		await Fade.fade_long()
		
		# Trigger effects at the 5th image (index 4)
		if i == 4:
			trigger_effects()
			# Add screen shake for dramatic effect
			screen_shake()
		
		# Start voice if available
		var has_voice = false
		if i < voices.size() and voices[i] != null:
			var voice_resource = voices[i]
			voice_player.stream = voice_resource
			voice_player.play()
			has_voice = true
			print("Playing preloaded voice: ", i)
		
		# Show text with smooth letter fade-in
		await show_text_smooth(step["text"])
		
		# Wait for voice to finish completely (if voice is playing)
		if has_voice:
			await wait_for_voice_finish()
		else:
			# If no voice, add a pause for reading
			await get_tree().create_timer(2.0).timeout
		
		# Hide text before fade transition
		hide_text()
		
		# Small pause between scenes
		await get_tree().create_timer(0.5).timeout
		
		# Fade out
		await Fade.fade_in()
	
	# Fade out background music at the end
	stop_background_music()

func start_background_music() -> void:
	if music and music.stream:
		music.volume_db = -80.0  # Start very quiet
		music.play()
		# Fade in music over 2 seconds
		var music_tween = create_tween()
		if music_tween:
			music_tween.tween_property(music, "volume_db", 4, 5.0)  # Fade to reasonable volume
			print("Background music started with fade-in")

func stop_background_music() -> void:
	if music and music.playing:
		# Fade out music over 3 seconds
		var music_tween = create_tween()
		if music_tween:
			music_tween.tween_property(music, "volume_db", -80.0, 3.0)
			music_tween.tween_callback(music.stop)
			print("Background music fading out")

func trigger_effects() -> void:
	# Play effect1
	if effect1:
		if effect1.has_method("play"):
			effect1.play()
		elif effect1.has_method("emitting"):
			effect1.emitting = true
		print("Effect 1 triggered")
	
	# Play effect2
	if effect2:
		if effect2.has_method("play"):
			effect2.play()
		elif effect2.has_method("emitting"):
			effect2.emitting = true
		print("Effect 2 triggered")

func screen_shake() -> void:
	# Create a longer, more dramatic shake sequence
	var shake_count = 15  # Increased from 8
	var current_intensity = shake_intensity
	
	for i in range(shake_count):
		var random_offset = Vector2(
			randf_range(-current_intensity, current_intensity),
			randf_range(-current_intensity, current_intensity)
		)
		
		# Create individual tweens for each shake
		var shake_tween = create_tween()
		shake_tween.set_parallel(true)
		shake_tween.tween_property(image_display, "position", original_image_pos + random_offset, 0.08)  # Slightly slower
		shake_tween.tween_property(text_bar, "position", original_text_pos + random_offset * 0.3, 0.08)
		
		await shake_tween.finished
		
		# Reduce intensity more gradually for longer effect
		current_intensity *= 0.9  # Changed from 0.8 for gentler decay
	
	# Hold the shake for a moment before returning
	await get_tree().create_timer(0.3).timeout
	
	# Return to original positions smoothly
	var return_tween = create_tween()
	return_tween.set_parallel(true)
	return_tween.tween_property(image_display, "position", original_image_pos, 0.4)  # Slower return
	return_tween.tween_property(text_bar, "position", original_text_pos, 0.4)
	await return_tween.finished
	
	print("Screen shake triggered")

# Improved function to wait for voice completion
func wait_for_voice_finish() -> void:
	print("Waiting for voice to finish...")
	
	# Wait until voice actually starts playing (sometimes there's a delay)
	var start_wait = 0
	while not voice_player.playing and start_wait < 60: # Wait up to 1 second for start
		await get_tree().process_frame
		start_wait += 1
	
	# Now wait for it to finish
	while voice_player.playing:
		await get_tree().process_frame
	
	print("Voice finished playing")

# Smooth letter-by-letter text display with fade-in effect
func show_text_smooth(content: String) -> void:
	rich_text.clear()
	rich_text.text = content
	rich_text.visible_characters = 0
	
	# Start with text completely transparent
	rich_text.modulate.a = 0.0
	
	# Fade in the text area first
	var main_tween = create_tween()
	main_tween.tween_property(rich_text, "modulate:a", 1.0, 0.4)
	await main_tween.finished
	
	# Now reveal characters smoothly with a gentle glow effect
	var total_chars = content.length()
	var reveal_tween = create_tween()
	reveal_tween.set_parallel(true)
	
	# Smooth character reveal
	reveal_tween.tween_method(
		func(chars): rich_text.visible_characters = int(chars),
		0.0,
		float(total_chars),
		total_chars * text_speed
	)
	
	# Add a subtle pulse effect during typing
	for i in range(total_chars):
		await get_tree().create_timer(text_speed).timeout
		
		# Create a gentle pulse effect every few characters
		if i % 3 == 0:
			var pulse_tween = create_tween()
			pulse_tween.tween_property(rich_text, "modulate:a", 1.15, 0.05)
			pulse_tween.tween_property(rich_text, "modulate:a", 1.0, 0.1)
	
	# Ensure all characters are visible at the end
	rich_text.visible_characters = total_chars

func hide_text() -> void:
	# Smoothly fade out the text before scene transitions
	var hide_tween = create_tween()
	hide_tween.tween_property(rich_text, "modulate:a", 0.0, 0.5)
	await hide_tween.finished
