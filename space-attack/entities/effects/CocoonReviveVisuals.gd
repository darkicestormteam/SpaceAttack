extends Node2D

# Визуальная часть для возрождения Cocoon Shield.
# Жёлтая расширяющаяся волна.

func _ready() -> void:
	z_index = 10
	queue_redraw()


func _draw() -> void:
	# Внешний волновой контур (ярко-жёлтый)
	draw_arc(Vector2.ZERO, 1.0, 0.0, TAU, 64, Color(1.0, 0.9, 0.2, 0.85), 0.05)
	# Внутренний волновой контур (светло-жёлтый)
	draw_arc(Vector2.ZERO, 0.92, 0.0, TAU, 48, Color(1.0, 0.95, 0.5, 0.55), 0.03)
	# Полупрозрачная заливка
	draw_circle(Vector2.ZERO, 0.98, Color(1.0, 0.85, 0.1, 0.18))
