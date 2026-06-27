extends CanvasLayer

const MINI_ACHIEVEMENT_SCENE := preload("res://ui/popups/MiniAchievementNotification.tscn")

var _queue: Array = []
var _active_notification: Control = null


func _ready() -> void:
	layer = 128
	await get_tree().process_frame
	_connect_to_save_manager()


func _connect_to_save_manager() -> void:
	if not SaveManager:
		return
	if not SaveManager.has_signal("achievement_unlocked"):
		return
	if SaveManager.achievement_unlocked.is_connected(_on_achievement_unlocked):
		return
	
	SaveManager.achievement_unlocked.connect(_on_achievement_unlocked)


func _on_achievement_unlocked(ach_id: String, ach_data: Dictionary) -> void:
	_queue.append({"id": ach_id, "data": ach_data})
	
	if _active_notification == null:
		_show_next()


func _show_next() -> void:
	if _queue.is_empty():
		return
	
	var entry = _queue.pop_front()
	var notification: Control = MINI_ACHIEVEMENT_SCENE.instantiate()
	
	add_child(notification)
	notification.setup(entry.id, entry.data)
	
	_active_notification = notification
	
	if notification.has_signal("animation_finished"):
		if not notification.animation_finished.is_connected(_on_notification_done):
			notification.animation_finished.connect(_on_notification_done)
	else:
		await get_tree().create_timer(5.0).timeout
		_on_notification_done()


func _on_notification_done() -> void:
	_active_notification = null
	_show_next()