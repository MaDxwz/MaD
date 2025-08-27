extends Node2D

@export var target_scene: String = "res://scenes/NextScene.tscn"

@onready var camera = $player/Camera2D
@onready var player = $player
@onready var anim = $mainscene
@onready var anim_sprite := $player/AnimatedSprite2D
@onready var animation_locked = get_node("player")

var returning = false
var original_position: Vector2

func _ready() -> void:
	animation_locked.animation_locked = true
	original_position = camera.position
	Fade.connect("fade_almost_finished", Callable(self, "on_fade_almost_finished"))
	await Fade.fade_long4()
	

func _physics_process(delta: float) -> void:
	if returning:
		camera.position = camera.position.lerp(original_position, 3 * delta)
		if camera.position.distance_to(original_position) < 1:
			camera.position = original_position

func on_fade_almost_finished():
	anim_sprite.play("idle")
	anim.play("follow")
	await anim.animation_finished
	animation_locked.animation_locked = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == player:
		await Fade.fade_long2()
		get_tree().change_scene_to_file(target_scene)

func _on_area_2d_2_body_entered(body: Node2D) -> void:
	if body == player:
		anim_sprite.play("idle")
		animation_locked.animation_locked = true
		anim.play("down")
		await anim.animation_finished
		returning = true
		animation_locked.animation_locked = false
