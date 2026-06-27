extends Node

## Менеджер интеграции с Yandex Games SDK.
##
## Выполняет инициализацию SDK, лидерборда и предоставляет
## унифицированные методы для показа рекламы, работы с таблицей
## лидеров и отправки отзыва.
##
## Использование:
##   await AdsManager.init_async()
##   AdsManager.show_interstitial()
##   await AdsManager.show_interstitial_and_wait()
##   AdsManager.show_rewarded()
##   await AdsManager.request_review_if_possible()
##   AdsManager.leaderboard_set_score("score", 1000)

signal init_started()
signal init_completed(success: bool)
signal init_failed(error_message: String)

# --- Interstitial ---
signal interstitial_opened()
signal interstitial_closed(was_shown: bool)
signal interstitial_error(error_message: String)
signal interstitial_offline()

# --- Rewarded Video ---
signal rewarded_video_opened()
signal rewarded_video_closed()
signal rewarded_video_error(error_message: String)
signal rewarded_video_rewarded()

# --- Leaderboard ---
signal leaderboard_ready()
signal leaderboard_score_submitted()
signal leaderboard_score_failed(error_message: String)
signal leaderboard_entries_received(data: Dictionary)
signal leaderboard_entries_failed(error_message: String)
signal leaderboard_player_entry_received(entry: Dictionary)
signal leaderboard_player_entry_failed(error_message: String)

# --- Feedback ---
signal review_possible()
signal review_not_possible(reason: Variant)
signal review_completed(feedback_sent: bool)
signal review_failed(error_message: String)


## Ссылка на экземпляр YandexGamesSDK (устанавливается при инициализации)
var sdk: Variant

## Флаг успешной инициализации SDK
var is_sdk_ready: bool = false
var _is_sdk_ready: bool = false

## Флаг готовности leaderboard
var is_leaderboard_ready: bool = false
var _is_leaderboard_ready: bool = false

## Флаг — идёт ли сейчас показ рекламы
var is_ad_showing: bool = false
var _is_ad_showing: bool = false


# ============================================================
# Инициализация
# ============================================================

## Инициализировать Yandex SDK и лидерборд.
## Вызывать один раз при старте игры (после загрузки главного меню).
func init_async() -> bool:
	init_started.emit()
	
	# 1. Найти или создать YandexGamesSDK
	sdk = _resolve_sdk()
	if sdk == null:
		_init_fail("YandexGamesSDK node not found and could not be created")
		return false
	
	# 2. Инициализация SDK
	if not sdk.is_inited():
		var init_ok: Variant = await sdk.init()
		if not init_ok:
			_init_fail("SDK initialization failed")
			return false
	
	# 3. Сообщаем платформе, что игра готова
	sdk.game_ready()
	
	# 4. Инициализация leaderboard
	var lb_ok: Variant = await sdk.leaderboard.init()
	if lb_ok == true:
		_is_leaderboard_ready = true
		leaderboard_ready.emit()
	else:
		push_warning("[AdsManager] Leaderboard init failed, skipping")
	
	# 5. Подписываемся на сигналы рекламы
	_connect_adv_signals()
	
	# 6. Подписываемся на фокус окна (автопауза / автостарт)
	if not sdk.is_connected("game_api_paused", _on_game_api_paused):
		sdk.game_api_paused.connect(_on_game_api_paused)
	if not sdk.is_connected("game_api_resumed", _on_game_api_resumed):
		sdk.game_api_resumed.connect(_on_game_api_resumed)
	
	_is_sdk_ready = true
	is_sdk_ready = true
	init_completed.emit(true)
	return true


func _init_fail(msg: String) -> void:
	_is_sdk_ready = false
	is_sdk_ready = false
	_is_leaderboard_ready = false
	is_leaderboard_ready = false
	push_error("[AdsManager] " + msg)
	init_failed.emit(msg)
	init_completed.emit(false)


func _resolve_sdk() -> Variant:
	# Ищем уже существующий узел YandexSDK (зарегистрированный как автозагрузка)
	var existing: Variant = get_node_or_null("/root/YandexSDK")
	if existing != null and existing is YandexGamesSDK:
		return existing
	# Ищем YandexGamesSDK (старое имя)
	existing = get_node_or_null("/root/YandexGamesSDK")
	if existing != null and existing is YandexGamesSDK:
		return existing
	
	# Пробуем найти через class_name
	for node in get_tree().root.get_children():
		if node is YandexGamesSDK:
			return node
	
	# Если не нашли — создаём
	var sdk_node: YandexGamesSDK = YandexGamesSDK.new()
	sdk_node.name = "YandexGamesSDK"
	get_tree().root.add_child(sdk_node, true)
	return sdk_node


func _connect_adv_signals() -> void:
	if sdk == null or sdk.adv == null:
		return
	
	var adv = sdk.adv
	if not adv.is_connected("show_fullscreen_opened", _on_interstitial_opened):
		adv.show_fullscreen_opened.connect(_on_interstitial_opened)
	if not adv.is_connected("show_fullscreen_closed", _on_interstitial_closed):
		adv.show_fullscreen_closed.connect(_on_interstitial_closed)
	if not adv.is_connected("show_fullscreen_error", _on_interstitial_error):
		adv.show_fullscreen_error.connect(_on_interstitial_error)
	if not adv.is_connected("show_fullscreen_offline", _on_interstitial_offline):
		adv.show_fullscreen_offline.connect(_on_interstitial_offline)
	
	if not adv.is_connected("show_rewarded_video_opened", _on_rewarded_opened):
		adv.show_rewarded_video_opened.connect(_on_rewarded_opened)
	if not adv.is_connected("show_rewarded_video_closed", _on_rewarded_closed):
		adv.show_rewarded_video_closed.connect(_on_rewarded_closed)
	if not adv.is_connected("show_rewarded_video_error", _on_rewarded_error):
		adv.show_rewarded_video_error.connect(_on_rewarded_error)
	if not adv.is_connected("show_rewarded_video_rewarded", _on_rewarded_rewarded):
		adv.show_rewarded_video_rewarded.connect(_on_rewarded_rewarded)


# ============================================================
# Gameplay API (обязательно для Yandex)
# ============================================================

## Сообщить SDK о старте игрового процесса.
func gameplay_start() -> void:
	if sdk != null and sdk.is_inited():
		sdk.gameplay_start()


## Сообщить SDK об остановке игрового процесса.
func gameplay_stop() -> void:
	if sdk != null and sdk.is_inited():
		sdk.gameplay_stop()


# ============================================================
# Interstitial (полноэкранная реклама)
# ============================================================

## Показать межстраничную рекламу (без ожидания).
func show_interstitial() -> void:
	if _is_ad_showing:
		push_warning("[AdsManager] Already showing an ad")
		return
	if sdk == null or not sdk.is_inited():
		push_warning("[AdsManager] SDK not ready, cannot show interstitial")
		interstitial_closed.emit(false)
		return
	
	_is_ad_showing = true
	is_ad_showing = true
	sdk.adv.show_fullscreen()


## Показать межстраничную рекламу и дождаться её закрытия.
## Использовать через await:
##   await AdsManager.show_interstitial_and_wait()
func show_interstitial_and_wait() -> void:
	if not can_show_interstitial():
		return
	
	# Подписываемся одноразово на сигналы завершения
	var ad_done := false
	var on_close := func(_was_shown: bool) -> void:
		ad_done = true
	var on_err := func(_msg: String) -> void:
		ad_done = true
	var on_off := func() -> void:
		ad_done = true
	
	interstitial_closed.connect(on_close)
	interstitial_error.connect(on_err)
	interstitial_offline.connect(on_off)
	
	show_interstitial()
	
	# Ждём пока ad_done не станет true
	while not ad_done:
		await get_tree().process_frame
	
	# Отписываемся
	interstitial_closed.disconnect(on_close)
	interstitial_error.disconnect(on_err)
	interstitial_offline.disconnect(on_off)


## Проверить, доступна ли межстраничная реклама по кулдауну.
func can_show_interstitial() -> bool:
	if sdk == null or not sdk.is_inited():
		return false
	return sdk.adv.crl_show_fullscreen.get_requests_count() > 0


# ============================================================
# Rewarded Video (награждаемая реклама)
# ============================================================

## Показать награждаемую рекламу.
## При успешном просмотре будет сигнал rewarded_video_rewarded.
func show_rewarded() -> void:
	if _is_ad_showing:
		push_warning("[AdsManager] Already showing an ad")
		return
	if sdk == null or not sdk.is_inited():
		push_warning("[AdsManager] SDK not ready, cannot show rewarded video")
		rewarded_video_closed.emit()
		return
	
	_is_ad_showing = true
	is_ad_showing = true
	sdk.adv.show_rewarded_video()


## Показать награждаемую рекламу и дождаться результата.
## Возвращает true, если награда получена.
func show_rewarded_and_wait() -> bool:
	if sdk == null or not sdk.is_inited():
		return false
	
	var got_reward := false
	var ad_closed := false
	
	var on_rewarded := func() -> void:
		got_reward = true
	var on_closed := func() -> void:
		ad_closed = true
	var on_error := func(_msg: String) -> void:
		ad_closed = true
	
	rewarded_video_rewarded.connect(on_rewarded)
	rewarded_video_closed.connect(on_closed)
	rewarded_video_error.connect(on_error)
	
	show_rewarded()
	
	# Ждём пока не закроется
	while not ad_closed:
		await get_tree().process_frame
	
	rewarded_video_rewarded.disconnect(on_rewarded)
	rewarded_video_closed.disconnect(on_closed)
	rewarded_video_error.disconnect(on_error)
	
	return got_reward


# ============================================================
# Leaderboard
# ============================================================

## Отправить счёт в таблицу лидеров.
func leaderboard_set_score(name: String, score: int, extra_data: String = "") -> void:
	if sdk == null or not sdk.is_inited() or not _is_leaderboard_ready:
		push_warning("[AdsManager] Leaderboard not ready")
		leaderboard_score_failed.emit("Leaderboard not ready")
		return
	
	var success: Variant = await sdk.leaderboard.set_score(name, score, extra_data)
	if success == true:
		leaderboard_score_submitted.emit()
	else:
		leaderboard_score_failed.emit("Failed to set score")


## Получить записи лидерборда.
func leaderboard_get_entries(
	name: String,
	include_user: bool = false,
	quantity_around: int = 5,
	quantity_top: int = 5
) -> void:
	if sdk == null or not sdk.is_inited() or not _is_leaderboard_ready:
		push_warning("[AdsManager] Leaderboard not ready")
		leaderboard_entries_failed.emit("Leaderboard not ready")
		return
	
	var data: Variant = await sdk.leaderboard.get_entries(
		name, include_user, quantity_around, quantity_top
	)
	if data != null:
		leaderboard_entries_received.emit(data)
	else:
		leaderboard_entries_failed.emit("Failed to get entries")


## Получить запись текущего игрока в лидерборде.
func leaderboard_get_player_entry(name: String) -> void:
	if sdk == null or not sdk.is_inited() or not _is_leaderboard_ready:
		push_warning("[AdsManager] Leaderboard not ready")
		leaderboard_player_entry_failed.emit("Leaderboard not ready")
		return
	
	var entry: Variant = await sdk.leaderboard.get_player_entry(name)
	if entry != null:
		leaderboard_player_entry_received.emit(entry)
	else:
		leaderboard_player_entry_failed.emit(
			sdk.leaderboard.get_player_entry_code()
		)


# ============================================================
# Feedback (отзыв об игре)
# ============================================================

## Проверить, можно ли запросить отзыв, и если да — показать окно.
## Возвращает true, если отзыв был отправлен.
func request_review_if_possible() -> bool:
	if sdk == null or not sdk.is_inited():
		push_warning("[AdsManager] SDK not ready for feedback")
		return false
	
	var can: Variant = await sdk.feedback.can_review()
	if can != true:
		review_not_possible.emit(sdk.feedback.get_can_review_reason())
		return false
	
	review_possible.emit()
	var sent: Variant = await sdk.feedback.request_review()
	review_completed.emit(sent)
	return sent


# ============================================================
# Вспомогательное
# ============================================================

## Получить информацию об окружении (язык, домен, app ID).
func get_environment() -> Dictionary:
	if sdk == null or not sdk.is_inited():
		return {}
	return sdk.get_environment()


## ID игры в Яндекс.Играх.
func get_app_id() -> String:
	var env := get_environment()
	return env.get("app", {}).get("id", "")


# ============================================================
# In-App Purchases (Yandex Payments)
# ============================================================

## Инициализировать платежи.
## Вызывать после init_async(), если нужны покупки.
func payments_init() -> Variant:
	if sdk == null or not sdk.is_inited():
		return false
	var ok: Variant = await sdk.payments.init()
	return ok == true


## Проверить необработанные покупки и начислить награды.
## Обязательно для модерации (п. 1.13.1).
## Вызывать после init_async() и payments_init().
func check_unconsumed_purchases() -> void:
	if sdk == null or not sdk.is_inited() or not sdk.payments.is_inited():
		push_warning("[AdsManager] Payments not inited, cannot check unconsumed purchases")
		return
	
	var purchases: Variant = await sdk.payments.get_purchases()
	if purchases == null or not purchases is Array:
		return
	if purchases.is_empty():
		return
	
	print("[AdsManager] Found ", purchases.size(), " unconsumed purchase(s)")
	
	for purchase in purchases:
		var pid: String = purchase.get("product_id", "")
		var token: String = purchase.get("purchase_token", "")
		
		match pid:
			"all_modules":
				print("[AdsManager] Processing unconsumed all_modules")
				_apply_all_modules()
				if not token.is_empty():
					await sdk.payments.consume_purchase(token)
			"remove_ads":
				print("[AdsManager] Processing unconsumed remove_ads")
				SaveManager.ads_removed = true
				SaveManager.save_game()
			_:
				push_warning("[AdsManager] Unknown unconsumed purchase: ", pid)


## Вспомогательный: начислить все модули и скины
func _apply_all_modules() -> void:
	SaveManager.all_modules_purchased = true
	for mid in SaveManager.ALL_MODULE_IDS:
		SaveManager.add_module(mid)
	if not SaveManager.owned_modules.has("laser"):
		SaveManager.add_module("laser")
	for sid in SaveManager.SKIN_CHEST_POOL:
		var parts: PackedStringArray = sid.split("_")
		SaveManager.unlock_skin(parts[1], int(parts[2]))
	SaveManager.on_achievement_progress_check()
	SaveManager.save_game()


## Получить каталог доступных товаров.
func get_catalog() -> Array:
	if sdk == null or not sdk.payments.is_inited():
		return []
	var products: Variant = await sdk.payments.get_catalog()
	if products is Array:
		return products
	return []


## Совершить покупку по ID товара.
## Возвращает Dictionary с деталями покупки или null.
func purchase(product_id: String, developer_payload: String = "") -> Dictionary:
	if sdk == null or not sdk.payments.is_inited():
		return {}
	var result: Variant = await sdk.payments.purchase(product_id, developer_payload)
	if result == null:
		return {}
	return result


## Потратить расходную покупку (чтобы можно было купить снова).
func consume_purchase(purchase_token: String) -> bool:
	if sdk == null or not sdk.payments.is_inited():
		return false
	var ok: Variant = await sdk.payments.consume_purchase(purchase_token)
	return ok == true


## Купить "Все модули" — открывает все модули игры.
## ID товара в панели Яндекса: "all_modules"
func purchase_all_modules() -> void:
	var purchase_data: Variant = await purchase("all_modules")
	if purchase_data == null:
		printerr("[AdsManager] Purchase all_modules failed")
		return
	SaveManager.all_modules_purchased = true
	
	# Открываем все модули
	for mid in SaveManager.ALL_MODULE_IDS:
		SaveManager.add_module(mid)
	# Также базовый лазер
	if not SaveManager.owned_modules.has("laser"):
		SaveManager.add_module("laser")
	# Разблокируем все скины из пула
	for sid in SaveManager.SKIN_CHEST_POOL:
		var parts: PackedStringArray = sid.split("_")
		SaveManager.unlock_skin(parts[1], int(parts[2]))
	
	SaveManager.on_achievement_progress_check()
	SaveManager.save_game()
	
	# Потребляем покупку (расходный товар)
	await consume_purchase(purchase_data.purchase_token)
	print("[AdsManager] All modules purchased!")


## Купить "Отключение рекламы" — реклама больше не показывается.
## ID товара в панели Яндекса: "remove_ads"
func purchase_remove_ads() -> void:
	var purchase_data: Variant = await purchase("remove_ads")
	if purchase_data == null:
		printerr("[AdsManager] Purchase remove_ads failed")
		return
	SaveManager.ads_removed = true
	SaveManager.save_game()
	print("[AdsManager] Ads removed permanently!")


## Проверить, можно ли показывать межстраничную рекламу (с учётом покупки).
func can_show_interstitial_safe() -> bool:
	if SaveManager.ads_removed:
		return false
	return can_show_interstitial()


## Проверить, можно ли показывать rewarded рекламу (с учётом покупки).
func can_show_rewarded_safe() -> bool:
	if SaveManager.ads_removed:
		return false
	if sdk == null or not sdk.is_inited():
		return false
	return true


## Язык интерфейса пользователя (ISO 639-1).
func get_lang() -> String:
	var env := get_environment()
	return env.get("i18n", {}).get("lang", "ru")


## Сбросить прогресс игрока на сервере Яндекс.Игр и локально.
## Использует player.setData({}) + player.setStats({}) для полной очистки.
## Возвращает true, если сброс выполнен успешно.
func reset_player_progress() -> bool:
	if sdk == null or not sdk.is_inited() or sdk.player == null:
		push_warning("[AdsManager] SDK not ready, cannot reset progress")
		return false
	
	if not sdk.player.is_inited():
		var inited: Variant = await sdk.player.init()
		if inited != true:
			push_warning("[AdsManager] Player init failed, cannot reset progress")
			return false
	
	# 1. Сброс всех сохранённых данных (player.setData({}))
	var data_ok: Variant = await sdk.player.set_data({})
	if data_ok != true:
		push_warning("[AdsManager] Failed to reset player data on server")
	
	# 2. Сброс числовой статистики (player.setStats({}))
	var stats_ok: Variant = await sdk.player.set_stats({})
	if stats_ok != true:
		push_warning("[AdsManager] Failed to reset player stats on server")
	
	# 3. Сброс локального прогресса (SaveManager)
	if SaveManager:
		SaveManager.set_defaults()
		SaveManager.save_game()
		print("[AdsManager] Local progress reset")
	
	return data_ok == true and stats_ok == true


## TLD домена (com, tr, ...).
func get_tld() -> String:
	var env := get_environment()
	return env.get("i18n", {}).get("tld", "com")


# ============================================================
# Обработчики сигналов рекламы (YandexAdv → AdsManager)
# ============================================================

func _on_interstitial_opened() -> void:
	gameplay_stop()
	interstitial_opened.emit()

func _on_interstitial_closed(was_shown: bool) -> void:
	_is_ad_showing = false
	is_ad_showing = false
	interstitial_closed.emit(was_shown)
	gameplay_start()

func _on_interstitial_error(error_message: String) -> void:
	_is_ad_showing = false
	is_ad_showing = false
	interstitial_error.emit(error_message)

func _on_interstitial_offline() -> void:
	_is_ad_showing = false
	is_ad_showing = false
	interstitial_offline.emit()


func _on_rewarded_opened() -> void:
	gameplay_stop()
	rewarded_video_opened.emit()

func _on_rewarded_closed() -> void:
	_is_ad_showing = false
	is_ad_showing = false
	rewarded_video_closed.emit()
	gameplay_start()

func _on_rewarded_error(error_message: String) -> void:
	_is_ad_showing = false
	is_ad_showing = false
	rewarded_video_error.emit(error_message)

func _on_rewarded_rewarded() -> void:
	rewarded_video_rewarded.emit()


# ============================================================
# Обработчики game_api_paused / resumed
# ============================================================

func _on_game_api_paused() -> void:
	gameplay_stop()

func _on_game_api_resumed() -> void:
	gameplay_start()
