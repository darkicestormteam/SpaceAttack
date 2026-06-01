extends Node2D

const DURATION: float = 0.3


func _ready() -> void:
	z_index = 10
	queue_redraw()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, DURATION)
	await tween.finished
	queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 20.0, Color(0.1, 1, 0.3, 0.5))
	draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 24, Color(0.3, 1, 0.5, 0.7), 1.5)