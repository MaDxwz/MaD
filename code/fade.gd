extends CanvasLayer

@onready var rect: ColorRect = $ColorRect
@onready var anim: AnimationPlayer = $AnimationPlayer

signal fade_almost_finished  

func fade_out() -> void:
	rect.visible = true
	anim.play("fade.out")
	await anim.animation_finished
	rect.visible = false

func fade_in() -> void:
	rect.visible = true
	anim.play("fade.in")
	await anim.animation_finished
	rect.visible = false

func fade_long() -> void:
	rect.visible = true
	anim.play("long.fade")
	await anim.animation_finished
	rect.visible = false

func fade_long2() -> void:
	rect.visible = true
	anim.play("long.fade2")
	await anim.animation_finished
	rect.visible = false

func fade_long3() -> void:
	rect.visible = true
	anim.play("long.fade3")
	await anim.animation_finished
	rect.visible = false

func fade_long4() -> void:
	rect.visible = true
	anim.play("long.fade4")
	await anim.animation_finished
	rect.visible = false


func _emit_fade_almost_finished():
	emit_signal("fade_almost_finished")
