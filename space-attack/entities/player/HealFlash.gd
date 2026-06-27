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
	draw_circle(Vector2.ZERO, 28.8, Color(0.13, 1.0, 0.39, 0.5))  # 20 × 1.2 × 1.2
	draw_arc(Vector2.ZERO, 34.6, 0.0, TAU, 24, Color(0.39, 1.0, 0.65, 0.7), 1.5)  # 24 × 1.2 × 1.2
