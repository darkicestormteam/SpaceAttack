extends Node2D
class_name Explosion

## Эффект взрыва: проигрывает анимацию + звук, удаляется по окончании.

@export var sprite_scale: float = 5.0
@export var keep_after_anim: bool = false  # обычно удаляем

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var sound: AudioStreamPlayer2D = $Sound


func _ready() -> void:
	if sprite:
		sprite.scale = Vector2(sprite_scale, sprite_scale)
		sprite.animation_finished.connect(_on_anim_finished)
		sprite.play(&"explode")
	if sound:
		sound.play()


func _on_anim_finished() -> void:
	if not keep_after_anim:
		queue_free()
