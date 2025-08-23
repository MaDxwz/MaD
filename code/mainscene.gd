extends Node2D

@onready var anim = $mainscene
var animation_locked: bool = false 
@onready var anim_sprite := $player/AnimatedSprite2D

func _ready() -> void:
	Fade.connect("fade_almost_finished", Callable(self, "on_fade_almost_finished"))
	

func on_fade_almost_finished():
	anim_sprite.play("idle")
	anim.play("follow")
	await anim.animation_finished
	animation_locked = false
