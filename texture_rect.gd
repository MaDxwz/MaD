extends TextureRect

func _ready():
	# Create gradient for smooth transparent bottom bar
	var gradient_texture = GradientTexture2D.new()
	var gradient = Gradient.new()
	
	# Set gradient points (Gradient starts with 2 default points at 0.0 and 1.0)
	gradient.set_color(0, Color(0, 0, 0, 0))        # Top: fully transparent
	gradient.set_color(1, Color(0, 0, 0, 0.35))     # Bottom: slightly opaque
	
	# Add intermediate points for smooth fading
	gradient.add_point(0.7, Color(0, 0, 0, 0))      # Stay transparent
	gradient.add_point(0.85, Color(0, 0, 0, 0.15))  # Start fading in
	gradient.add_point(0.95, Color(0, 0, 0, 0.3))   # Almost transparent black
	
	# Set up the gradient texture
	gradient_texture.gradient = gradient
	gradient_texture.fill = GradientTexture2D.FILL_LINEAR
	gradient_texture.fill_from = Vector2(0, 0)
	gradient_texture.fill_to = Vector2(0, 1)
	
	# Apply to this TextureRect
	texture = gradient_texture
	
	# Set up positioning and scaling
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	stretch_mode = TextureRect.STRETCH_SCALE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
