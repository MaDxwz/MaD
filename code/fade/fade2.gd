extends CanvasLayer

@onready var anim: AnimationPlayer = $AnimationPlayer

func fade_out1() -> void:
	anim.play("fade.out")
	await anim.animation_finished

func fade_in1() -> void:
	anim.play("fade.in")
	await anim.animation_finished
