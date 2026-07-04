extends HBoxContainer

signal module_selected(module_id: String)

const DRAG_THRESHOLD := 12.0

var module_id: String = ""
var _start_pos := Vector2.ZERO
var _is_pressing := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_on_press_start(event.position)
		else:
			_on_press_end(event.position)
		return

	if event is InputEventMouseMotion and _is_pressing:
		_on_drag(event.position)
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			_on_press_start(event.position)
		else:
			_on_press_end(event.position)
		return

	if event is InputEventScreenDrag and _is_pressing:
		_on_drag(event.position)


func _on_press_start(pos: Vector2) -> void:
	_is_pressing = true
	_start_pos = pos
	modulate.a = 0.7


func _on_drag(pos: Vector2) -> void:
	if _is_pressing and pos.distance_to(_start_pos) > DRAG_THRESHOLD:
		_is_pressing = false
		modulate.a = 1.0


func _on_press_end(pos: Vector2) -> void:
	if not _is_pressing:
		return
	_is_pressing = false
	modulate.a = 1.0
	if pos.distance_to(_start_pos) <= DRAG_THRESHOLD and not module_id.is_empty():
		accept_event()
		# Откладываем эмиссию сигнала, чтобы событие release успело дойти до ScrollContainer
		module_selected.emit.call_deferred(module_id)


func reset_state() -> void:
	_is_pressing = false
	modulate.a = 1.0
