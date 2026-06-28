extends Node

## Глобальный менеджер игрового процесса.
##
## Отвечает за:
##   - GameplayAPI (gameplay_start / gameplay_stop) для Yandex SDK
##   - game_ready() — уведомление платформы о готовности игры
##   - Управление состояниями игры (меню, бой, пауза)
##
## Использование:
##   GameManager.notify_game_ready()
##   GameManager.on_battle_start()
##   GameManager.on_battle_end()
##   GameManager.on_game_paused()
##   GameManager.on_game_resumed()

## Текущее состояние игры
enum GameState {
	UNKNOWN,       # Не инициализировано
	LOADING,       # Загрузка
	MENU,          # Главное меню / Ангар
	BATTLE,        # Активный бой
	PAUSED,        # Пауза
	GAME_OVER,     # Смерть / завершение
}

## Текущее состояние
var current_state: GameState = GameState.UNKNOWN:
	get = _get_current_state
var _current_state: GameState = GameState.UNKNOWN

## Флаг — игра полностью загружена
var is_game_ready: bool = false


func _ready() -> void:
	# Ищем AdsManager и подключаемся к его сигналу инициализации
	# чтобы после готовности SDK вызвать game_ready()
	var ads_manager = get_node_or_null("/root/AdsManager")
	if ads_manager != null:
		if not ads_manager.is_connected("init_completed", _on_ads_init_completed):
			ads_manager.init_completed.connect(_on_ads_init_completed)
	else:
		push_warning("[GameManager] AdsManager not found, game_ready() will not be called automatically")


func _on_ads_init_completed(success: bool) -> void:
	if success:
		notify_game_ready()
	set_state(GameState.MENU)


# ============================================================
# Управление состоянием
# ============================================================

func _get_current_state() -> GameState:
	return _current_state


func set_state(new_state: GameState) -> void:
	var prev = _current_state
	_current_state = new_state
	
	match new_state:
		GameState.MENU:
			# Всегда останавливаем gameplay при входе в меню,
			# чтобы иконка в Я.Консоли была красной (gameplay_stop)
			on_battle_end()
		GameState.BATTLE:
			on_battle_start()
		GameState.PAUSED:
			on_game_paused()
		GameState.GAME_OVER:
			on_battle_end()
	
	print("[GameManager] State: %s → %s" % [GameState.keys()[prev], GameState.keys()[new_state]])


# ============================================================
# Gameplay API (вызывают gameplay_start / gameplay_stop)
# ============================================================

## Уведомить платформу, что игра готова к взаимодействию.
## Вызывать после инициализации SDK и загрузки всех ресурсов.
func notify_game_ready() -> void:
	var ads = get_node_or_null("/root/AdsManager")
	if ads != null and ads.has_method("init_async"):
		# Если AdsManager уже проинициализирован, можно не ждать
		if ads.is_sdk_ready:
			_call_game_ready()
	else:
		_call_game_ready()


func _call_game_ready() -> void:
	# game_ready() уже вызывается в AdsManager.init_async()
	is_game_ready = true
	print("[GameManager] Game ready notified")


## Вызывать при старте боя / начале уровня.
func on_battle_start() -> void:
	if _current_state != GameState.BATTLE:
		var ads = get_node_or_null("/root/AdsManager")
		if ads != null and ads.has_method("gameplay_start"):
			ads.gameplay_start()
		elif _fallback_sdk():
			_fallback_sdk().gameplay_start()
		print("[GameManager] Battle started — gameplay_start()")


## Вызывать при завершении боя (победа / смерть / выход в меню).
## Переключает gameplay на stop.
func on_battle_end() -> void:
	var ads = get_node_or_null("/root/AdsManager")
	if ads != null and ads.has_method("gameplay_stop"):
		ads.gameplay_stop()
	elif _fallback_sdk():
		_fallback_sdk().gameplay_stop()
	print("[GameManager] Battle ended — gameplay_stop()")


## Вызывать при паузе.
func on_game_paused() -> void:
	var ads = get_node_or_null("/root/AdsManager")
	if ads != null and ads.has_method("gameplay_stop"):
		ads.gameplay_stop()
	elif _fallback_sdk():
		_fallback_sdk().gameplay_stop()
	print("[GameManager] Game paused — gameplay_stop()")


## Вызывать при возобновлении игры (снятие паузы).
func on_game_resumed() -> void:
	var ads = get_node_or_null("/root/AdsManager")
	if ads != null and ads.has_method("gameplay_start"):
		ads.gameplay_start()
	elif _fallback_sdk():
		_fallback_sdk().gameplay_start()
	print("[GameManager] Game resumed — gameplay_start()")


## Вызывать при возвращении в меню из боя.
## Если was_in_battle=true, нужно остановить gameplay.
func on_return_to_menu(was_in_battle: bool) -> void:
	if was_in_battle:
		on_battle_end()


func _fallback_sdk() -> YandexGamesSDK:
	return get_node_or_null("/root/YandexGamesSDK")