extends Node

## Глобальный менеджер фокуса окна.
## Автоматически ставит игру на паузу при потере фокуса (сворачивание,
## переключение вкладки) и снимает паузу при возврате фокуса.
## Работает в любой сцене (ангар, битва, меню).
##
## ВАЖНО: Подписываемся ТОЛЬКО на NOTIFICATION_WM_WINDOW_FOCUS_OUT/IN.
## НЕ подписываемся на game_api_paused/resumed от YandexSDK,
## потому что они приходят при показе/закрытии рекламы,
## а фокус окна при этом не теряется.

signal focus_lost()
signal focus_gained()

var _is_focused: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_on_focus_lost()
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		_on_focus_gained()


func _on_focus_lost() -> void:
	if not _is_focused:
		return
	_is_focused = false
	
	# Глушим Master-шину (выключает ВСЕ звуки)
	var master_idx := AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_mute(master_idx, true)
	
	# Ставим на паузу
	get_tree().paused = true
	
	focus_lost.emit()
	print("[FocusManager] Focus lost — game paused, audio muted")


func _on_focus_gained() -> void:
	if _is_focused:
		return
	_is_focused = true
	
	# Восстанавливаем звук
	var master_idx := AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_mute(master_idx, false)
	
	# Снимаем паузу (кроме случая, когда открыто меню паузы в Main)
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_node("PauseMenu"):
		var pause_menu = main_scene.get_node("PauseMenu")
		if pause_menu.has_method("is_menu_visible") and pause_menu.is_menu_visible():
			print("[FocusManager] Focus gained — pause menu is open, keeping pause")
			return
		# fallback: проверяем panel.visible
		if pause_menu.has_node("MenuPanel") and pause_menu.get_node("MenuPanel").visible:
			print("[FocusManager] Focus gained — pause menu panel visible, keeping pause")
			return
	
	get_tree().paused = false
	
	focus_gained.emit()
	print("[FocusManager] Focus gained — game resumed, audio restored")
