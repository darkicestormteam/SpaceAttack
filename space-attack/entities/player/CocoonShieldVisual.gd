extends Node2D

const GOLIATH_SCALE: float = 1.5

@onready var shield_sprite: Sprite2D = $ShieldAll
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var is_goliath: bool = false
var _is_ready: bool = false


func _ready() -> void:
	visible = false
	shield_sprite.visible = true


## Установить цвет щита (модулирует спрайт, сохраняя исходную прозрачность)
func set_shield_color(color: Color) -> void:
	shield_sprite.modulate = Color(color.r, color.g, color.b, shield_sprite.modulate.a)


## Активировать щит: показать и проиграть анимацию run
func activate() -> void:
	visible = true
	scale = Vector2(GOLIATH_SCALE, GOLIATH_SCALE) if is_goliath else Vector2.ONE
	animation_player.play("run")
	_is_ready = true


## Деактивировать щит после поглощения урона
func deactivate() -> void:
	visible = false
	animation_player.stop()
	_is_ready = false


## Вернуть true если щит сейчас активен (видим)
func is_shield_active() -> bool:
	return visible and _is_ready
