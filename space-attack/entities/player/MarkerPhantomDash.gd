extends Marker2D

## Маркер для Phantom Dash.
## Появляется в месте двойного тапа, и корабль делает рывок к нему.

var target_position: Vector2 = Vector2.ZERO
var is_active: bool = false


func _ready() -> void:
	hide()
	process_mode = PROCESS_MODE_ALWAYS


func set_dash_target(screen_pos: Vector2) -> void:
	# Конвертируем экранные координаты в мировые через камеру
	var cam: Camera2D = get_viewport().get_camera_2d()
	var world_pos: Vector2 = cam.global_position + (screen_pos - get_viewport_rect().size / 2.0) / cam.zoom
	global_position = world_pos
	target_position = world_pos
	is_active = true
	show()
	# Авто-скрытие через 0.5 сек
	var tw := create_tween()
	tw.tween_interval(0.5)
	tw.tween_callback(func():
		is_active = false
		hide()
	)
