extends Node2D

func _ready() -> void:
	z_index = 5
	queue_redraw()

func _draw() -> void:
	draw_arc(Vector2.ZERO, 36.0, 0.0, TAU, 48, Color(0.2, 0.4, 1, 0.35), 3.0)
	draw_circle(Vector2.ZERO, 32.0, Color(0.1, 0.3, 1, 0.08))