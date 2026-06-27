extends Node2D

# Временный визуальный эффект: круг (аура щита), который постепенно
# увеличивается и затухает. Удаляется автоматически.
# Цвет по умолчанию — неоновый голубой (для Shield / Composite Armor).
# Для кокона передаётся жёлтый: flash_color(0.2, Color(1.0, 0.85, 0.1)).

var _elapsed: float = 0.0
var _duration: float = 0.2
var _max_radius: float = 69.1  # 48 × 1.2 × 1.2
var _color: Color = Color(0.2, 0.9, 1.0)  # неоновый голубой
var _fill_color: Color = Color(0.3, 0.95, 1.0)  # неоновый голубой


func _ready() -> void:
	z_index = 5
	queue_redraw()


func flash(duration: float) -> void:
	flash_color(duration, Color(0.2, 0.9, 1.0), Color(0.3, 0.95, 1.0))


func flash_color(duration: float, outline: Color, fill: Color) -> void:
	_duration = duration
	_color = outline
	_fill_color = fill
	_elapsed = 0.0
	queue_redraw()


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
	var outline := Color(_color.r, _color.g, _color.b, alpha)
	var fill := Color(_fill_color.r, _fill_color.g, _fill_color.b, alpha * 0.25)
	# Внешний круг
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, outline, 4.0)
	# Полупрозрачная заливка
	draw_circle(Vector2.ZERO, radius, fill)
