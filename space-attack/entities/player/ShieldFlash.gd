extends Node2D

# Временный визуальный эффект: зелёный круг (аура щита), который постепенно
# увеличивается и затухает. Удаляется автоматически.

var _elapsed: float = 0.0
var _duration: float = 0.2
var _max_radius: float = 48.0


func _ready() -> void:
	z_index = 5
	queue_redraw()


func flash(duration: float) -> void:
	_duration = duration


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= _duration:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	if _duration <= 0.0:
		return
	var t: float = clamp(_elapsed / _duration, 0.0, 1.0)
	# Радиус растёт от 0 до max
	var radius: float = lerp(0.0, _max_radius, t)
	# Прозрачность падает со временем
	var alpha: float = lerp(0.7, 0.0, t)
	var color := Color(0.2, 1.0, 0.4, alpha)
	# Внешний круг
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, color, 4.0)
	# Полупрозрачная заливка
	draw_circle(Vector2.ZERO, radius, Color(0.3, 1.0, 0.5, alpha * 0.25))
