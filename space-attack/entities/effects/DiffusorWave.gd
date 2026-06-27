extends Area2D

# Визуальный эффект для модуля Diffusor.
# Фиолетовая расширяющаяся волна — только визуал, без урона.
# Радиус соответствует DIFFUSOR_RADIUS (200px).

const RADIUS: float = 200.0
const DURATION: float = 0.25

var _visuals: Node2D


func _ready() -> void:
	# Визуальная часть
	_visuals = Node2D.new()
	_visuals.name = "Visuals"
	add_child(_visuals)
	_visuals.set_script(preload("res://entities/effects/DiffusorVisuals.gd"))

	# Анимация расширения от 0 до RADIUS
	scale = Vector2(0.001, 0.001)
	_visuals.scale = Vector2(0.001, 0.001)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1, 1), DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_visuals, "scale", Vector2(RADIUS, RADIUS), DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_visuals, "modulate:a", 0.0, DURATION).set_trans(Tween.TRANS_LINEAR)

	# Авто-удаление
	await get_tree().create_timer(DURATION).timeout
	queue_free()
