extends CanvasLayer

## Обратный отсчёт 3-2-1 после воскрешения.
## Каждая цифра за 1 секунду уменьшается до 0 и исчезает.

signal countdown_finished

@onready var countdown_label: Label = %CountdownLabel

var _numbers: Array[int] = [3, 2, 1]
var _current_index: int = 0


func start() -> void:
	_current_index = 0
	_show_next_number()


func _show_next_number() -> void:
	if _current_index >= _numbers.size():
		countdown_finished.emit()
		queue_free()
		return
	
	var num := _numbers[_current_index]
	countdown_label.text = str(num)
	countdown_label.modulate = Color(1, 1, 1, 1)
	countdown_label.scale = Vector2(1, 1)
	
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(countdown_label, "modulate:a", 0.0, 1.0)
	tween.parallel().tween_property(countdown_label, "scale", Vector2(0.1, 0.1), 1.0)
	tween.tween_callback(_on_number_done)


func _on_number_done() -> void:
	_current_index += 1
	_show_next_number()
