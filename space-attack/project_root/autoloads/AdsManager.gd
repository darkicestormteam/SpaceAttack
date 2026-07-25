extends Node

## Менеджер интеграции с Yandex Games SDK.
##
## Выполняет инициализацию SDK, лидерборда и предоставляет
## унифицированные методы для показа рекламы, работы с таблицей
## лидеров и отправки отзыва.
##
## Использование:
##   await AdsManager.init_async()
##   AdsManager.queue_interstitial()
##   AdsManager.queue_rewarded(callback)  # callback примет true/false
##   await AdsManager.queue_completed

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

# --- Reward Flow ---
## Единый сигнал завершения rewarded потока. Срабатывает один раз при любом исходе.
signal ad_flow_finished()

# --- Feedback ---
signal review_possible()
signal review_not_possible(reason: Variant)
signal review_completed(feedback_sent: bool)
signal review_failed(error_message: String)

# --- Queue ---
signal queue_completed()

# --- Purchase Availability ---
## Сигнал об изменении доступности покупок (для Hangar и других UI)
signal purchase_availability_changed(available: bool)
## Сигнал — проверка непотреблённых покупок завершена (для SaveManager)
signal purchases_checked()


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

# --- Очередь рекламы ---
enum QueueItemType { INTERSTITIAL, REWARDED }

## Очередь запросов на показ рекламы.
## Каждый элемент: {type: QueueItemType, credits_to_double: int, resume_callback: Callable}
var _ad_queue: Array[Dictionary] = []
## Флаг, что очередь сейчас обрабатывается
var _queue_processing: bool = false
## Флаг, что очередь в процессе (для блокировки _resume_game)
var _queue_in_progress: bool = false
## Результат последнего rewarded видео
var _last_rewarded_result: bool = false

# Флаг готовности платежей
var _is_payments_ready: bool = false


# ============================================================
# API проверки доступности
# ============================================================

## Можно ли совершать покупки? Возвращает true только если SDK, player и payments готовы.
## Если false — кнопки покупок должны быть заблокированы.
func can_purchase() -> bool:
	if sdk == null or not sdk.is_inited():
		return false
	if sdk.player == null:
		return false
	if not sdk.player.is_inited():
		return false
	if not _is_payments_ready:
		return false
	return true


## Проверить доступность покупок и вызвать сигнал при изменении.
func _on_purchase_availability_changed() -> void:
	var available = can_purchase()
	purchase_availability_changed.emit(available)
	print("[AdsManager] Purchase availability changed: ", available)


# ============================================================
# API очереди
# ============================================================

## Добавить interstitial в очередь.
func queue_interstitial() -> void:
	_ad_queue.append({"type": QueueItemType.INTERSTITIAL, "credits_to_double": 0})
	_process_ad_queue()


## Добавить rewarded видео для удвоения кредитов.
func queue_rewarded_double(credits_to_double: int) -> void:
	_ad_queue.append({"type": QueueItemType.REWARDED, "credits_to_double": credits_to_double})
	_process_ad_queue()


## Обработать следующий элемент очереди.
func _process_ad_queue() -> void:
	if _queue_processing or _is_ad_showing:
		return
	if _ad_queue.is_empty():
		_queue_in_progress = false
		queue_completed.emit()
		return
	
	_queue_processing = true
	_queue_in_progress = true
	
	var item = _ad_queue.pop_front()
	
	match item.type:
		QueueItemType.INTERSTITIAL:
			await _show_internal_interstitial()
		QueueItemType.REWARDED:
			var got_reward = await _show_internal_rewarded()
			if got_reward and item.credits_to_double > 0:
				if SaveManager:
					# Начисляем банк + удвоение (банк * 2)
					SaveManager.add_credits(item.credits_to_double * 2)
					print("[AdsManager] Credits doubled! +%d" % (item.credits_to_double * 2))
	
	_queue_processing = false
	_queue_in_progress = false
	
	# Если в очереди ещё есть элементы — обрабатываем следующий
	# Иначе завершаем очередь
	if not _ad_queue.is_empty():
		_process_ad_queue()
	else:
		queue_completed.emit()


# ============================================================
# Внутренний показ interstitial
# ============================================================

func _show_internal_interstitial() -> void:
	if not can_show_interstitial():
		print("[AdsManager] Interstitial not available (cooldown)")
		# Всё равно завершаем очередь, чтобы не блокировать await queue_completed
		queue_completed.emit()
		return
	
	# Ожидаем сигнала закрытия рекламы
	var on_close := func(_was_shown: bool) -> void:
		pass
	var on_err := func(_msg: String) -> void:
		pass
	var on_off := func() -> void:
		pass
	
	interstitial_closed.connect(on_close)
	interstitial_error.connect(on_err)
	interstitial_offline.connect(on_off)
	
	show_interstitial()
	
	# Ждём любой из сигналов закрытия (один await — без цикла)
	await interstitial_closed
	
	interstitial_closed.disconnect(on_close)
	interstitial_error.disconnect(on_err)
	interstitial_offline.disconnect(on_off)


# ============================================================
# Внутренний показ rewarded
# ============================================================

## Вспомогательные поля для _show_internal_rewarded
var _reward_got: bool = false
var _reward_flow_done: bool = false


func _show_internal_rewarded() -> bool:
	if sdk == null or not sdk.is_inited():
		return false
	
	# Сбрасываем состояние
	_reward_got = false
	_reward_flow_done = false
	
	# Подписываемся на сигналы Yandex SDK 
	# _arg = null защищает от Signal Signature Mismatch (JS может слать объект вместо строки)
	rewarded_video_rewarded.connect(_on_ad_rewarded_internal, CONNECT_ONE_SHOT)
	rewarded_video_closed.connect(_on_ad_closed_internal, CONNECT_ONE_SHOT)
	rewarded_video_error.connect(_on_ad_error_internal, CONNECT_ONE_SHOT)
	
	show_rewarded()
	
	# Ждём единый сигнал завершения — без циклов, без таймеров
	await ad_flow_finished
	
	# Отписка на всякий случай (CONNECT_ONE_SHOT уже отписал, но для надёжности)
	if rewarded_video_rewarded.is_connected(_on_ad_rewarded_internal):
		rewarded_video_rewarded.disconnect(_on_ad_rewarded_internal)
	if rewarded_video_closed.is_connected(_on_ad_closed_internal):
		rewarded_video_closed.disconnect(_on_ad_closed_internal)
	if rewarded_video_error.is_connected(_on_ad_error_internal):
		rewarded_video_error.disconnect(_on_ad_error_internal)
	
	print("[AdsManager] _show_internal_rewarded returning got_reward=", _reward_got)
	return _reward_got


# --- Внутренние обработчики сигналов ---

func _on_ad_rewarded_internal(_arg = null) -> void:
	print("[AdsManager] Internal: reward received")
	_reward_got = true
	_finish_reward_flow()

func _on_ad_closed_internal(_arg = null) -> void:
	print("[AdsManager] Internal: closed")
	_finish_reward_flow()

func _on_ad_error_internal(_arg = null) -> void:
	print("[AdsManager] Internal: error")
	_finish_reward_flow()


func _finish_reward_flow() -> void:
	# Защита от двойного вызова — если SDK пришлёт и rewarded, и closed
	if _reward_flow_done:
		return
	_reward_flow_done = true
	ad_flow_finished.emit()


# ============================================================
# Инициализация
# ============================================================

## Инициализировать Yandex SDK и лидерборд.
## Вызывать один раз при старте игры (после загрузки главного меню).
func init_async() -> bool:
	if _is_sdk_ready:
		init_completed.emit(true)
		return true
	
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
	
	# 3. Инициализация leaderboard
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
	
	# Автоматически инициализируем платежи, чтобы can_purchase() мог вернуть true
	# и кнопка IAP не была заблокирована навсегда.
	# Не используем await — fire-and-forget, ошибки не критичны.
	call_deferred("_auto_init_payments")
	
	return true


## Инициализировать платежи (автоматически, без ожидания).
func _auto_init_payments() -> void:
	if _is_payments_ready:
		return
	if sdk == null or not sdk.is_inited():
		return
	var ok: Variant = await sdk.payments.init()
	if ok == true:
		_is_payments_ready = true
		print("[AdsManager] Auto-payments initialized, purchases available")
		_on_purchase_availability_changed()
	else:
		_is_payments_ready = false
		printerr("[AdsManager] Auto-payments init failed")
		_on_purchase_availability_changed()


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


## Проверить, доступна ли межстраничная реклама по кулдауну.
func can_show_interstitial() -> bool:
	if sdk == null or not sdk.is_inited():
		return false
	return sdk.adv.crl_show_fullscreen.get_requests_count() > 0


# ============================================================
# Rewarded Video (награждаемая реклама)
# ============================================================

## Показать награждаемую рекламу (без ожидания).
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
## Возвращает true, если игрок получил награду.
func show_rewarded_and_wait() -> bool:
	return await _show_internal_rewarded()


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
	if ok == true:
		_is_payments_ready = true
		print("[AdsManager] Payments initialized, purchases available")
		_on_purchase_availability_changed()
	else:
		_is_payments_ready = false
		printerr("[AdsManager] Payments init failed")
		_on_purchase_availability_changed()
	return ok == true


## Проверить необработанные покупки и начислить награды.
## Обязательно для модерации (п. 1.13.1).
## Вызывать после init_async() и payments_init().
func check_unconsumed_purchases() -> void:
	if sdk == null or not sdk.is_inited():
		push_warning("[AdsManager] SDK not inited")
		return
		
	# Если платежи еще не инициализированы — инициализируем их принудительно!
	if not sdk.payments.is_inited():
		print("[AdsManager] Payments not inited, initializing now for unconsumed check...")
		var inited = await sdk.payments.init()
		if not inited:
			push_warning("[AdsManager] Payments init failed, cannot check unconsumed")
			return
			
	var purchases: Variant = await sdk.payments.get_purchases()
	if purchases == null or not purchases is Array:
		return
	if purchases.is_empty():
		print("[AdsManager] No unconsumed purchases found.")
		return
		
	print("[AdsManager] Found ", purchases.size(), " unconsumed purchase(s)")
	
	# Если покупок нет — всё равно испускаем сигнал, чтобы SaveManager знал, что можно загружать облако
	# Реально purchases уже проверены выше на is_empty, и return бы не сработал,
	# но для единообразия сигнал всегда будет в конце метода.
	
	for purchase in purchases:
		var pid: String = purchase.get("product_id", "")
		var token: String = purchase.get("purchase_token", "")
		print("[AdsManager] Processing pending purchase: ", pid)
		
		# Проверка: если token пустой — не вызывать consume_purchase
		if token.is_empty():
			printerr("[AdsManager] CRITICAL: Empty purchase token for ", pid, " — skipping consume")
			continue
		
		var granted: bool = false
		
		match pid:
			"all_modules":
				print("[AdsManager] Granting all_modules...")
				_apply_all_modules()
				granted = true
			"remove_ads":
				print("[AdsManager] Granting remove_ads...")
				if SaveManager:
					if "no_ads_purchased" in SaveManager:
						SaveManager.no_ads_purchased = true
					SaveManager.save_game()
					granted = true
			_:
				# Неизвестный pid — не можем выдать награду, не consum'им
				printerr("[AdsManager] Unknown pending purchase ID: ", pid, " — cannot grant, skipping consume")
		
		# Consume ТОЛЬКО после успешной выдачи награды
		if granted:
			print("[AdsManager] Consuming token for ", pid)
			await sdk.payments.consume_purchase(token)
			print("[AdsManager] Token consumed successfully.")
		else:
			printerr("[AdsManager] Failed to grant reward for ", pid, " — NOT consuming purchase. Will retry on next launch.")
	
	# Сигнал для SaveManager — проверка покупок завершена, можно загружать облако
	purchases_checked.emit()


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
## Дёргает SDK с ретраями (до 3 попыток с задержкой 1 сек).
func get_catalog() -> Array:
	if sdk == null or not sdk.payments.is_inited():
		return []
	
	var max_attempts := 3
	for attempt in range(1, max_attempts + 1):
		var products: Variant = await sdk.payments.get_catalog()
		if products is Array:
			return products
		if attempt < max_attempts:
			printerr("[AdsManager] Catalog fetch attempt ", attempt, " failed, retrying in 1s...")
			await get_tree().create_timer(1.0).timeout
		else:
			printerr("[AdsManager] Catalog fetch failed after ", max_attempts, " attempts")
	
	return []


## Совершить покупку по ID товара.
## Возвращает Dictionary:
##   {status: "success", data: result_dictionary_from_sdk}
##   {status: "cancelled", data: ""}
##   {status: "error", data: "error_description"}
func purchase(product_id: String, developer_payload: String = "") -> Dictionary:
	if sdk == null or not sdk.payments.is_inited():
		return {"status": "error", "data": "Payments not inited"}
	var result: Variant = await sdk.payments.purchase(product_id, developer_payload)
	
	# Проверка на null — SDK может вернуть null при отмене или ошибке
	if result == null:
		# Яндекс SDK возвращает null при отмене (пользователь закрыл платёжное окно)
		return {"status": "cancelled", "data": ""}
	
	# Проверка, что это Dictionary с ожидаемыми полями
	if result is Dictionary and result.has("purchase_token"):
		return {"status": "success", "data": result}
	
	# Любой другой результат — ошибка
	return {"status": "error", "data": str(result)}


## Потратить расходную покупку (чтобы можно было купить снова).
func consume_purchase(purchase_token: String) -> bool:
	if sdk == null or not sdk.payments.is_inited():
		return false
	var ok: Variant = await sdk.payments.consume_purchase(purchase_token)
	return ok == true


## Купить "Все модули" — открывает все модули игры.
## ID товара в панели Яндекса: "all_modules"
func purchase_all_modules() -> void:
	# Защита от повторной покупки
	if SaveManager.all_modules_purchased == true:
		print("[AdsManager] All modules already purchased, skipping.")
		return
	
	var purchase_result: Dictionary = await purchase("all_modules")
	if purchase_result.status != "success":
		printerr("[AdsManager] Purchase all_modules failed: ", purchase_result.get("data", "unknown"))
		return
	
	var purchase_data: Variant = purchase_result.get("data", {})
	# Проверка purchase_token — data это словарь от SDK
	var token: String = ""
	if purchase_data is Dictionary:
		token = purchase_data.get("purchase_token", "")
	if token.is_empty():
		printerr("[AdsManager] CRITICAL: Missing purchase token in purchase_data!")
		return
	
	# 1. Выдаём награду
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
	
	# 2. Сохраняем в облако (плашка Яндекса висит, ожидая завершения сохранения — это нормально!)
	var cloud_save_success := false
	if SaveManager.has_method(&"save_game_critical_async"):
		var saved = await SaveManager.save_game_critical_async()
		if not saved:
			printerr("[AdsManager] CRITICAL: Cloud save failed after IAP purchase! Will retry on next launch.")
		else:
			print("[AdsManager] IAP data saved to cloud successfully")
			cloud_save_success = true
	else:
		SaveManager.save_game()
		cloud_save_success = true
	
	# 3. Consume ТОЛЬКО после успешного сохранения в облако
	if cloud_save_success:
		await consume_purchase(token)
		print("[AdsManager] Purchase consumed successfully, Yandex UI should close.")
	else:
		printerr("[AdsManager] CRITICAL: Cloud save failed — NOT consuming purchase. Will retry on next launch via check_unconsumed_purchases().")
		return
		
	print("[AdsManager] All modules purchased!")


## Вручную вызывает GameReady API, когда UI готов.
func notify_game_ready() -> void:
	if sdk != null and sdk.is_inited():
		sdk.game_ready()
		print("[AdsManager] GameReady API called.")


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
	
	# 4. Сброс настроек звука (AudioManager хранит их в отдельном файле)
	var audio = get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("reset_settings"):
		audio.reset_settings()
		print("[AdsManager] Audio settings reset")
	
	return data_ok == true and stats_ok == true


## TLD домена (com, tr, ...).
func get_tld() -> String:
	var env := get_environment()
	return env.get("i18n", {}).get("tld", "com")


# ============================================================
# Обработчики сигналов рекламы (YandexAdv → AdsManager)
# ============================================================

func _on_interstitial_opened() -> void:
	interstitial_opened.emit()
	# Ставим игру на паузу и глушим звук на время рекламы
	get_tree().paused = true
	_mute_all_audio(true)

func _on_interstitial_closed(was_shown: bool) -> void:
	_is_ad_showing = false
	is_ad_showing = false
	# Снимаем паузу и восстанавливаем звук после рекламы
	get_tree().paused = false
	_mute_all_audio(false)
	# Возвращаем фокус на canvas (важно для Web/браузера)
	_focus_game_canvas()
	interstitial_closed.emit(was_shown)
	# Автозапуск очереди, если есть ожидающие элементы
	if not _ad_queue.is_empty() and not _queue_processing:
		_process_ad_queue()

func _on_interstitial_error(error_message: String) -> void:
	_is_ad_showing = false
	is_ad_showing = false
	_mute_all_audio(false)
	interstitial_error.emit(error_message)
	interstitial_closed.emit(false)
	# Автозапуск очереди, если есть ожидающие элементы
	if not _ad_queue.is_empty() and not _queue_processing:
		_process_ad_queue()

func _on_interstitial_offline() -> void:
	_is_ad_showing = false
	is_ad_showing = false
	_mute_all_audio(false)
	interstitial_offline.emit()
	interstitial_closed.emit(false)
	# Автозапуск очереди, если есть ожидающие элементы
	if not _ad_queue.is_empty() and not _queue_processing:
		_process_ad_queue()


func _on_rewarded_opened() -> void:
	rewarded_video_opened.emit()
	get_tree().paused = true
	_mute_all_audio(true)

func _on_rewarded_closed() -> void:
	_is_ad_showing = false
	is_ad_showing = false
	get_tree().paused = false
	_mute_all_audio(false)
	# Возвращаем фокус на canvas (важно для Web/браузера)
	_focus_game_canvas()
	rewarded_video_closed.emit()
	# Автозапуск очереди, если есть ожидающие элементы
	if not _ad_queue.is_empty() and not _queue_processing:
		_process_ad_queue()

func _on_rewarded_error(error_message: String) -> void:
	_is_ad_showing = false
	is_ad_showing = false
	get_tree().paused = false
	_mute_all_audio(false)
	rewarded_video_error.emit(error_message)
	rewarded_video_closed.emit()
	# Автозапуск очереди, если есть ожидающие элементы
	if not _ad_queue.is_empty() and not _queue_processing:
		_process_ad_queue()

func _on_rewarded_rewarded() -> void:
	rewarded_video_rewarded.emit()


# ============================================================
# Управление звуком при показе рекламы
# ============================================================

func _mute_all_audio(muted: bool) -> void:
	var master_idx := AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_mute(master_idx, muted)
		print("[AdsManager] Master bus muted=", muted)


# ============================================================
# Возврат фокуса на canvas после рекламы (важно для Web/браузера)
# ============================================================

## Принудительно возвращает фокус клавиатуры на canvas игры.
## Без этого в браузере после закрытия рекламы клавиатура не работает,
## пока игрок не кликнет по игре мышкой.
func _focus_game_canvas() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("""
		(function() {
			try {
				var canvas = document.querySelector('canvas');
				if (canvas) {
					canvas.focus();
					canvas.setAttribute('tabindex', '0');
					canvas.style.outline = 'none';
				}
				window.focus();
			} catch(e) {}
		})()
	""")


# ============================================================
# Обработчики game_api_paused / resumed
# ============================================================

func _on_game_api_paused() -> void:
	gameplay_stop()

func _on_game_api_resumed() -> void:
	print("[AdsManager] Game API Resumed received")
	
	# НЕ вызываем gameplay_stop() — плагин Mist1351 сам управляет
	# стартом/стопом при game_api_resume/pause.
	# Наша задача — только не дать запуститься gameplay_start() если мы в меню.
	# Если мы в бою — плагин уже корректно включил gameplay.
	# Если мы в меню — при следующем переходе GameManager.set_state() вызовет
	# on_battle_end() который сделает gameplay_stop().
	
	var gm = get_node_or_null("/root/GameManager")
	if gm == null:
		print("[AdsManager] GameManager not found, skipping gameplay stop")
		return
	
	var is_battle := false
	if gm.has_method("get_current_state"):
		is_battle = (gm.get_current_state() == gm.GameState.BATTLE)
	elif "_current_state" in gm:
		is_battle = (gm._current_state == gm.GameState.BATTLE)
	
	if is_battle:
		print("[AdsManager] Gameplay API is correctly active (In Battle)")
	else:
		print("[AdsManager] In Menu, gameplay will be stopped on next set_state()")
	
	
	# При возврате фокуса — перепроверяем доступность платежей
	_on_purchase_availability_changed()
	
	# Если платежи ещё не инициализированы — пробуем
	if not _is_payments_ready:
		call_deferred("_auto_init_payments")
