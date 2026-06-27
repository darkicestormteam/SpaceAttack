extends ParallaxBackground

@export var scroll_speed: Vector2 = Vector2(0, -100)


func _ready() -> void:
	# Отключаем слежение за камерой, чтобы камера offset при тряске
	# не дёргал parallax-фон.
	follow_viewport_enabled = false


func _process(delta: float) -> void:
	scroll_offset -= scroll_speed * delta
