extends Node2D

const DURATION: float = 0.15
const RADIUS: float = 40.0


func _ready() -> void:
	z_index = 10
	queue_redraw()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(3.0, 3.0), DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, DURATION).set_trans(Tween.TRANS_LINEAR)
	await tween.finished
	queue_free()


func _draw() -> void:
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 32, Color(1, 0.6, 0.2, 0.8), 2.0)
	draw_circle(Vector2.ZERO, RADIUS * 0.5, Color(1, 0.4, 0.1, 0.15))
