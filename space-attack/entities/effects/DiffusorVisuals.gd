extends Node2D

# Визуальная часть Diffusor. Фиолетовая волна, масштабируется родительским Area2D.
# Аналогично ShockwaveVisuals.gd.

func _ready() -> void:
	z_index = 10
	queue_redraw()


func _draw() -> void:
	# Внешний волновой контур (фиолетовый, +30% яркости)
	draw_arc(Vector2.ZERO, 1.0, 0.0, TAU, 64, Color(0.91, 0.39, 1.0, 0.8), 0.04)
	# Внутренний волновой контур (светлее, +30% яркости)
	draw_arc(Vector2.ZERO, 0.92, 0.0, TAU, 48, Color(1.0, 0.65, 1.0, 0.5), 0.03)
	# Полупрозрачная заливка (+30% яркости)
	draw_circle(Vector2.ZERO, 0.98, Color(0.78, 0.33, 1.0, 0.15))
