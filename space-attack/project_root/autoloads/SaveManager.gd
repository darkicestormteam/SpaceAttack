extends Node

signal achievement_unlocked(achievement_id: String, achievement_data: Dictionary)
## Сигнал — данные загружены (из локального файла или из облака)
signal data_loaded()

var credits: int = 0
var health_upgrade_level: int = 0
var high_score: int = 0

# Система сложностей
var difficulty_level: int = 0
var difficulty_unlocked: Array = [0]

var owned_modules: Dictionary = {}
var equipped_modules: Dictionary = {
	"weapon": "",
	"defense": "",
	"utility": ""
}

var unlocked_ships: Array = ["vanguard"]
var current_ship: String = "vanguard"

var ship_skins: Dictionary = {}

var all_modules_purchased: bool = false
var pending_leaderboard_score: int = 0

var session_credits_bank: int = 0
var pending_double_credits: int = 0

var achievements: Dictionary = {}
var credits_earned_total: int = 0

var persistent_enemies_killed_total: int = 0
var persistent_shotgun_kills: int = 0
var persistent_bosses_killed: int = 0
var persistent_modules_unlocked_count: int = 0
var persistent_chests_opened: int = 0

# Трекинг для ачивок
var tmp_enemies_killed_total: int = 0
var tmp_bosses_killed_total: int = 0
var tmp_phantom_dashes: int = 0
var tmp_goliath_charge_kills: int = 0
var tmp_shockwave_used: int = 0
var tmp_forsage_procs: int = 0
var tmp_tactical_accelerator_procs: int = 0
var tmp_health_packs_collected: int = 0
var tmp_cocoon_shield_blocked: int = 0
var tmp_nanobots_healed: int = 0
var tmp_rocket_kills: int = 0
var tmp_homing_rocket_kills: int = 0
var tmp_shotgun_kills: int = 0
var tmp_laser_mk2_kills: int = 0
var tmp_laser_pierce_kills: int = 0
var tmp_damage_taken_in_game: int = 0
var tmp_asteroid_phase: bool = false
var tmp_asteroid_damage_taken: bool = false
var tmp_highest_wave: int = 0
var tmp_current_ship: String = "vanguard"
var tmp_carrier_kill_without_damage: bool = false
var tmp_carrier_fight_damage_taken: bool = false
var tmp_last_kill_time: float = 0.0
var tmp_kill_count_fast: int = 0
var tmp_kill_types_fast: Array = []
var tmp_last_kill_fast_time: float = 0.0
var tmp_kill_count_total: int = 0
var tmp_plasma_stack_25_count: int = 0
var tmp_plasma_stack_value: int = 0
var tmp_laser_wall_survived: bool = false
var tmp_game_won: bool = false

const GREEDY_MODULES_REQUIRED: int = 30
const SKIN_COUNT: int = 3

const SKIN_COSTS: Dictionary = {0: 0, 1: 1000, 2: 2500}
const SHIP_COSTS: Dictionary = {"vanguard": 0, "phantom": 2000, "goliath": 5000}
const SHIP_NAMES: Dictionary = {"vanguard": "Вангвард", "phantom": "Фантом", "goliath": "Голиаф"}
const SKIN_NAMES: Dictionary = {0: "Стиль 1", 1: "Стиль 2", 2: "Стиль 3", 3: "Стиль 4", 4: "Стиль 5"}

const MODULE_SLOT_BY_TYPE: Dictionary = {"weapon": "weapon", "defense": "defense", "utility": "utility"}
const SAVE_PATH: String = "user://savegame.json"

const ALL_MODULE_IDS: Array = [
	"laser_mk2", "laser_pierce", "laser_plasma",
	"shotgun", "shotgun_whistle", "shotgun_pressure", "shotgun_heavy",
	"rocket", "rocket_mk2", "rocket_homing", "rocket_nuke",
	"light_armor", "shield", "composite_armor", "forsage",
	"tactical_accelerator", "diffusor", "cocoon_shield",
	"drone", "drone_rare", "drone_epic", "drone_legendary",
	"shockwave", "turbo", "nanobots"
]

const SKIN_CHEST_POOL: Array = [
	"skin_vanguard_1", "skin_vanguard_2",
	"skin_phantom_1", "skin_phantom_2",
	"skin_goliath_1", "skin_goliath_2"
]

const DEFAULT_MODULE_IDS: Array = ["laser"]

# ============================================================
# Версия сохранения
# ============================================================
## Версия формата. Старые файлы с меньшей версией игнорируются.
const SAVE_VERSION: int = 2

# ============================================================
# Константы облачного сохранения
# ============================================================
## Минимальный интервал между вызовами set_data (лимит API Яндекса)
const MIN_CLOUD_INTERVAL: float = 10.0
## Интервал автосохранения в облако
const AUTO_CLOUD_INTERVAL: float = 15.0

## Время последнего сохранения в облако
var _last_cloud_save_time: float = 0.0
## Таймер для автосохранения
var _auto_save_timer: float = 0.0
## Флаг — облако было успешно синхронизировано хотя бы раз
## Хранится в локальном savegame.json как "_cloud_was_synced"
var _cloud_was_synced: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Не загружаем сразу — ждём инициализацию AdsManager
	_on_ads_init(false)


func _on_ads_init(_success: bool = false) -> void:
	var ads = get_node_or_null("/root/AdsManager")
	if ads == null or not ads.is_sdk_ready or ads.sdk == null:
		# SDK ещё не готов — подписываемся на сигнал и ждём
		if ads != null and not ads.is_connected("init_completed", _on_ads_init):
			ads.init_completed.connect(_on_ads_init)
			print("[SaveManager] Waiting for AdsManager init...")
			return
		else:
			# AdsManager не найден — загружаем локально
			print("[SaveManager] AdsManager not found, loading from local...")
			load_game()
			return
	
	# Сначала грузим локально (мгновенно, UI увидит актуальный кеш)
	load_game()
	emit_signal("data_loaded")
	
	# SDK инициализирован — загружаем из облака.
	# После синхронизации ещё раз вызовем data_loaded, чтобы UI обновился
	call_deferred("_load_from_cloud")


# ============================================================
# Валидация версии сохранения
# ============================================================

## Проверить версию сохранения. Если устаревшая — вернуть null.
func _validate_save_data(data: Variant) -> Variant:
	if data is Dictionary:
		var ver = data.get("save_version", 0)
		if ver < SAVE_VERSION:
			print("[SaveManager] Save version mismatch: v", ver, " < v", SAVE_VERSION, " — ignoring old data")
			return null
	return data


# ============================================================
# Новая стратегия загрузки: "Облако — источник истины"
# ============================================================
# Сценарии:
# 1. Облако ДОСТУПНО + данные есть → облако главное, пишем в локал
# 2. Облако ДОСТУПНО + пусто + _cloud_was_synced == true → намеренный сброс → дефолт
# 3. Облако ДОСТУПНО + пусто + синхронизации не было → первый вход
#    - локальные есть → отправляем в облако
#    - локальных нет → дефолт
# 4. Облако НЕДОСТУПНО → офлайн с локальным кешем
# ============================================================

func _load_from_cloud() -> void:
	var ads = get_node_or_null("/root/AdsManager")
	if ads == null or ads.sdk == null or not ads.sdk.is_inited() or ads.sdk.player == null:
		# Сценарий 4: облако недоступно — играем офлайн
		print("[SaveManager] Cloud not available, loading local...")
		load_game()
		return
	
	# 1. Загружаем локальный файл (может быть null)
	var local_data = _load_local_raw_data()
	
	if local_data is Dictionary:
		_cloud_was_synced = local_data.get("_cloud_was_synced", false)
		# Проверяем версию — если старая, игнорируем локальные данные
		local_data = _validate_save_data(local_data)
	
	# 2. Убеждаемся, что player проинициализирован
	if not ads.sdk.player.is_inited():
		print("[SaveManager] Player not inited, initializing before cloud load...")
		var player_init = await ads.sdk.player.init()
		if player_init != true:
			print("[SaveManager] Player init failed, loading local...")
			load_game()
			return
	
	# 3. Загружаем из облака
	print("[SaveManager] Loading from cloud...")
	var cloud_data = await ads.sdk.player.get_data()
	
	# Проверяем версию облачных данных
	if cloud_data is Dictionary:
		cloud_data = _validate_save_data(cloud_data)
	
	var cloud_has_data = cloud_data is Dictionary and not cloud_data.is_empty()
	var cloud_is_empty = not cloud_has_data
	
	if cloud_is_empty:
		if _cloud_was_synced:
			# Сценарий 2: облако очистили намеренно (Clear Cloud Data)
			print("[SaveManager] Cloud empty but sync flag exists -> data was cleared, resetting to defaults...")
			set_defaults()
			_cloud_was_synced = false
			save_game()
			await _save_to_cloud_impl(true)
		elif local_data is Dictionary:
			# Сценарий 3a: первый вход, есть локальные данные
			print("[SaveManager] Cloud empty, first sync - uploading local data...")
			_apply_data(local_data)
			_cloud_was_synced = true
			save_game()
			await _save_to_cloud_impl(true)
		else:
			# Сценарий 3b: первый вход, нет данных
			print("[SaveManager] No data anywhere, setting defaults...")
			set_defaults()
			_cloud_was_synced = true
			save_game()
			await _save_to_cloud_impl(true)
	else:
		# Сценарий 1: облачные данные есть — облако главное
		print("[SaveManager] Cloud data found - applying cloud (truth source)...")
		_apply_data(cloud_data)
		_cloud_was_synced = true
		save_game()
	
	# В любом случае (сценарии 1, 2, 3) после синхронизации с облаком
	# обновляем UI. Исключение — сценарий 4 (облако недоступно), но там
	# data_loaded уже был вызван при локальной загрузке.
	emit_signal("data_loaded")


## Прочитать данные из локального файла без применения их в переменные.
func _load_local_raw_data() -> Variant:
	if not FileAccess.file_exists(SAVE_PATH):
		return null
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return null
	
	var json_str = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_str)
	if parse_result == OK:
		return json.data as Dictionary
	return null


func _get_save_data() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"credits": credits,
		"last_saved_at": Time.get_unix_time_from_system(),
		"health_upgrade_level": health_upgrade_level,
		"high_score": high_score,
		"owned_modules": owned_modules,
		"equipped_modules": equipped_modules,
		"unlocked_ships": unlocked_ships,
		"current_ship": current_ship,
		"ship_skins": ship_skins,
		"achievements": achievements,
		"credits_earned_total": credits_earned_total,
		"persistent_enemies_killed_total": persistent_enemies_killed_total,
		"persistent_shotgun_kills": persistent_shotgun_kills,
		"persistent_bosses_killed": persistent_bosses_killed,
		"persistent_modules_unlocked_count": persistent_modules_unlocked_count,
		"persistent_chests_opened": persistent_chests_opened,
		"all_modules_purchased": all_modules_purchased,
		"difficulty_unlocked": difficulty_unlocked.duplicate(),
		"difficulty_level": difficulty_level,
		"_cloud_was_synced": _cloud_was_synced,
	}


func _apply_data(data: Dictionary) -> void:
	credits = data.get("credits", 0)
	health_upgrade_level = data.get("health_upgrade_level", 0)
	high_score = data.get("high_score", 0)

	var loaded_owned = data.get("owned_modules", {})
	owned_modules = (loaded_owned as Dictionary).duplicate() if loaded_owned is Dictionary else {}

	var loaded_equipped = data.get("equipped_modules", {})
	equipped_modules = (loaded_equipped as Dictionary).duplicate() if loaded_equipped is Dictionary else {"weapon": "", "defense": "", "utility": ""}

	for slot in ["weapon", "defense", "utility"]:
		if not equipped_modules.has(slot):
			equipped_modules[slot] = ""

	for module_id in DEFAULT_MODULE_IDS:
		if not owned_modules.has(module_id):
			owned_modules[module_id] = 1

	var loaded_unlocked = data.get("unlocked_ships", [])
	unlocked_ships = loaded_unlocked.duplicate() if loaded_unlocked is Array else ["vanguard"]
	if not unlocked_ships.has("vanguard"):
		unlocked_ships.append("vanguard")
	current_ship = data.get("current_ship", "vanguard")

	var loaded_achievements = data.get("achievements", {})
	achievements = (loaded_achievements as Dictionary).duplicate() if loaded_achievements is Dictionary else {}
	credits_earned_total = data.get("credits_earned_total", 0)

	var loaded_diff = data.get("difficulty_unlocked", [0])
	difficulty_unlocked = loaded_diff.duplicate() if loaded_diff is Array and loaded_diff.size() > 0 else [0]

	persistent_enemies_killed_total = data.get("persistent_enemies_killed_total", 0)
	persistent_shotgun_kills = data.get("persistent_shotgun_kills", 0)
	persistent_bosses_killed = data.get("persistent_bosses_killed", 0)
	persistent_modules_unlocked_count = data.get("persistent_modules_unlocked_count", 0)
	persistent_chests_opened = data.get("persistent_chests_opened", 0)
	all_modules_purchased = data.get("all_modules_purchased", false)
	session_credits_bank = 0  # не сохраняется — только для сессии между битвой и ангаром

	var loaded_skins = data.get("ship_skins", {})
	ship_skins = (loaded_skins as Dictionary).duplicate(true) if loaded_skins is Dictionary else {}
	_init_default_skins()

	var to_remove: Array = []
	for mid in owned_modules:
		if mid is String and mid.begins_with("skin_"):
			var parts: PackedStringArray = str(mid).split("_")
			if parts.size() >= 3:
				var sid: String = parts[1]
				var sidx: int = int(parts[2])
				if not is_skin_unlocked(sid, sidx):
					to_remove.append(mid)
	for mid in to_remove:
		owned_modules.erase(mid)

	_update_persistent_modules_count()


func _get_cloud_time(cloud_data: Dictionary) -> int:
	return cloud_data.get("last_saved_at", 0)


func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		set_defaults()
		return _to_dict()

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_str = file.get_as_text()
		file.close()

		var json = JSON.new()
		var parse_result = json.parse(json_str)
		if parse_result == OK:
			var data = json.data as Dictionary
			# Проверяем версию — старая = игнорируем
			var valid_data = _validate_save_data(data)
			if valid_data is Dictionary:
				_cloud_was_synced = valid_data.get("_cloud_was_synced", false)
				_apply_data(valid_data)
			else:
				print("[SaveManager] Local save outdated, resetting...")
				set_defaults()
			return _to_dict()
		else:
			set_defaults()
		return _to_dict()
	else:
		set_defaults()
		return _to_dict()
	
	return _to_dict()


func _to_dict() -> Dictionary:
	return {
		"credits": credits,
		"health_upgrade_level": health_upgrade_level,
		"high_score": high_score,
		"difficulty_unlocked": difficulty_unlocked.duplicate(),
		"difficulty_level": difficulty_level,
		"owned_modules": owned_modules.duplicate(),
		"equipped_modules": equipped_modules.duplicate(),
		"unlocked_ships": unlocked_ships.duplicate(),
		"current_ship": current_ship,
		"ship_skins": ship_skins.duplicate(true),
		"achievements": achievements.duplicate(true),
		"credits_earned_total": credits_earned_total,
		"persistent_enemies_killed_total": persistent_enemies_killed_total,
		"persistent_shotgun_kills": persistent_shotgun_kills,
		"persistent_bosses_killed": persistent_bosses_killed,
		"persistent_modules_unlocked_count": persistent_modules_unlocked_count,
		"persistent_chests_opened": persistent_chests_opened,
		"_cloud_was_synced": _cloud_was_synced,
	}


func _init_default_skins() -> void:
	for ship_id in ["vanguard", "phantom", "goliath"]:
		if not ship_skins.has(ship_id):
			ship_skins[ship_id] = {"unlocked": [0], "current": 0}
		else:
			var entry = ship_skins[ship_id] as Dictionary
			if not entry.has("unlocked") or not entry["unlocked"] is Array:
				entry["unlocked"] = [0]
			elif 0 not in entry["unlocked"]:
				entry["unlocked"].append(0)
			if not entry.has("current"):
				entry["current"] = 0
		var mid := "skin_%s_0" % ship_id
		if not owned_modules.has(mid):
			owned_modules[mid] = 1


# ============================================================
# Автосохранение: раз в 15 секунд, с проверкой лимита API (10 сек)
# ============================================================
var _cloud_pending: bool = false


func _process(delta: float) -> void:
	if not _cloud_pending:
		return
	_auto_save_timer += delta
	if _auto_save_timer >= AUTO_CLOUD_INTERVAL:
		_auto_save_timer = 0.0
		_cloud_pending = false
		_save_to_cloud_impl(false)


func _mark_cloud_pending() -> void:
	if not _cloud_pending:
		_cloud_pending = true
		_auto_save_timer = 0.0


# ============================================================
# Сохранение
# ============================================================

func save_game() -> void:
	var data = _get_save_data()
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.new().stringify(data))
		file.close()


func save_game_async() -> void:
	save_game()
	_mark_cloud_pending()


func save_game_cloud_now() -> void:
	save_game()
	_cloud_pending = false
	_auto_save_timer = 0.0
	_save_to_cloud_impl(false)


func force_save_to_cloud() -> void:
	save_game()
	_cloud_pending = false
	_auto_save_timer = 0.0
	_last_cloud_save_time = 0.0
	_save_to_cloud_impl(false)


func save_game_critical_async() -> bool:
	save_game()
	_cloud_pending = false
	_auto_save_timer = 0.0
	_last_cloud_save_time = 0.0
	var success = await _save_to_cloud_impl(true)
	return success


func _save_to_cloud_impl(flush: bool) -> bool:
	var now = Time.get_ticks_msec() / 1000.0
	
	if not flush and (now - _last_cloud_save_time) < MIN_CLOUD_INTERVAL:
		print("[SaveManager] Cloud save skipped: too soon (", str(now - _last_cloud_save_time), "s < ", str(MIN_CLOUD_INTERVAL), "s)")
		return false
	
	var ads = get_node_or_null("/root/AdsManager")
	if ads == null or not ads.is_sdk_ready or ads.sdk == null:
		print("[SaveManager] Cloud save skipped: AdsManager not ready")
		return false
	if not ads.sdk.is_inited():
		print("[SaveManager] Cloud save skipped: SDK not inited")
		return false
	if ads.sdk.player == null:
		print("[SaveManager] Cloud save skipped: player is null")
		return false
	
	if not ads.sdk.player.is_inited():
		print("[SaveManager] Player not inited, initializing...")
		var player_init = await ads.sdk.player.init()
		if player_init != true:
			print("[SaveManager] Player init failed")
			return false
	
	_last_cloud_save_time = now
	
	var cloud_data = _get_save_data()
	var result = await ads.sdk.player.set_data(cloud_data, flush)
	if result == true:
		print("[SaveManager] Cloud save completed (flush=" + str(flush) + ")")
		_cloud_was_synced = true
		return true
	else:
		print("[SaveManager] Cloud save returned: " + str(result))
		return false


func set_defaults() -> void:
	credits = 0
	health_upgrade_level = 0
	high_score = 0
	owned_modules = {}
	for mid in DEFAULT_MODULE_IDS:
		owned_modules[mid] = 1
	equipped_modules = {"weapon": "laser", "defense": "", "utility": ""}
	unlocked_ships = ["vanguard"]
	current_ship = "vanguard"
	ship_skins = {}
	_init_default_skins()
	achievements = {}
	credits_earned_total = 0
	all_modules_purchased = false
	session_credits_bank = 0
	pending_double_credits = 0
	pending_leaderboard_score = 0
	persistent_enemies_killed_total = 0
	persistent_shotgun_kills = 0
	persistent_bosses_killed = 0
	persistent_modules_unlocked_count = 0
	persistent_chests_opened = 0
	difficulty_level = 0
	difficulty_unlocked = [0]
	_cloud_was_synced = false


# ============================================================
# Остальные методы (без изменений)
# ============================================================

func get_current_skin(ship_id: String) -> int:
	_init_default_skins()
	var entry = ship_skins.get(ship_id, {})
	return int(entry.get("current", 0))


func get_unlocked_skins(ship_id: String) -> Array:
	_init_default_skins()
	var entry = ship_skins.get(ship_id, {})
	return entry.get("unlocked", [0]).duplicate()


func is_skin_unlocked(ship_id: String, skin_index: int) -> bool:
	return skin_index in get_unlocked_skins(ship_id)


func select_skin(ship_id: String, skin_index: int) -> bool:
	if not is_skin_unlocked(ship_id, skin_index):
		return false
	if not ship_skins.has(ship_id):
		ship_skins[ship_id] = {"unlocked": [0], "current": 0}
	ship_skins[ship_id]["current"] = skin_index
	save_game_async()
	return true


func unlock_skin(ship_id: String, skin_index: int) -> bool:
	var max_idx = get_skin_count(ship_id)
	if skin_index < 0 or skin_index >= max_idx:
		return false
	_init_default_skins()
	if not ship_skins.has(ship_id):
		ship_skins[ship_id] = {"unlocked": [0], "current": 0}
	var entry = ship_skins[ship_id]
	if skin_index in entry["unlocked"]:
		return false
	entry["unlocked"].append(skin_index)
	var mid := "skin_%s_%d" % [ship_id, skin_index]
	if not owned_modules.has(mid):
		owned_modules[mid] = 1
	_update_persistent_modules_count()
	on_achievement_progress_check()
	save_game_async()
	return true


func get_skin_cost(skin_index: int) -> int:
	return SKIN_COSTS.get(skin_index, 99999)


func get_skin_name(ship_id: String, skin_index: int) -> String:
	var path := "res://data/modules/skin_%s_%d.tres" % [ship_id, skin_index]
	if ResourceLoader.exists(path):
		var res: Resource = load(path)
		if res != null and "name" in res:
			var name_str: String = str(res.name)
			if not name_str.is_empty():
				return name_str.strip_edges()
	return SKIN_NAMES.get(skin_index, "Стиль %d" % [skin_index + 1])


func get_skin_count(ship_id: String) -> int:
	var idx := 0
	var modules_dir := "res://data/modules/"
	while true:
		var tres_path := "%sskin_%s_%d.tres" % [modules_dir, ship_id, idx]
		if ResourceLoader.exists(tres_path):
			idx += 1
		else:
			break
	return max(idx, 1)


func is_ship_unlocked(ship_id: String) -> bool:
	return ship_id in unlocked_ships


func unlock_ship(ship_id: String) -> bool:
	if ship_id in unlocked_ships:
		return false
	unlocked_ships.append(ship_id)
	_update_persistent_modules_count()
	on_achievement_progress_check()
	save_game_async()
	return true


func select_ship(ship_id: String) -> bool:
	if not is_ship_unlocked(ship_id):
		return false
	current_ship = ship_id
	save_game_async()
	return true


func get_ship_cost(ship_id: String) -> int:
	return SHIP_COSTS.get(ship_id, 99999)


func get_ship_name(ship_id: String) -> String:
	return SHIP_NAMES.get(ship_id, ship_id)


func add_module(module_id: String) -> bool:
	if module_id == null or module_id.is_empty():
		return false
	if owned_modules.has(module_id):
		owned_modules[module_id] = int(owned_modules[module_id]) + 1
		return false
	owned_modules[module_id] = 1
	_update_persistent_modules_count()
	on_achievement_progress_check()
	save_game_async()
	return true


func _update_persistent_modules_count() -> void:
	var count := 0
	for mid in owned_modules:
		if not mid.begins_with("skin_"):
			if int(owned_modules[mid]) > 0:
				count += 1
	persistent_modules_unlocked_count = count
	for ship_id in ["vanguard", "phantom", "goliath"]:
		var entry = ship_skins.get(ship_id, {})
		var unlocked_arr = entry.get("unlocked", [])
		for _skin_idx in unlocked_arr:
			count += 1
	persistent_modules_unlocked_count = count


func has_module(module_id: String) -> bool:
	return owned_modules.has(module_id) and int(owned_modules[module_id]) > 0


func equip_module(slot: String, module_id: String) -> bool:
	if slot == "skin":
		if not module_id.begins_with("skin_"):
			return false
		var parts := module_id.split("_")
		if parts.size() < 3:
			return false
		var ship_id := parts[1]
		var skin_index := int(parts[2])
		return select_skin(ship_id, skin_index)
	
	var target_slot := slot
	if not target_slot in ["weapon", "defense", "utility"]:
		if MODULE_SLOT_BY_TYPE.has(target_slot):
			target_slot = MODULE_SLOT_BY_TYPE[target_slot]
		else:
			return false
	if not has_module(module_id):
		return false
	equipped_modules[target_slot] = module_id
	save_game_async()
	return true


func unequip_module(slot: String) -> void:
	if equipped_modules.has(slot):
		equipped_modules[slot] = ""
		save_game_async()


func get_equipped_in_slot(slot: String) -> String:
	if equipped_modules.has(slot):
		return equipped_modules[slot]
	return ""


func get_owned_module_ids() -> Array:
	return owned_modules.keys()


func spend_credits(amount: int) -> bool:
	if credits < amount:
		return false
	credits -= amount
	save_game_async()
	return true


func add_credits(amount: int) -> void:
	credits += amount
	credits_earned_total += amount
	on_credits_earned()
	save_game_async()


const ACHIEVEMENT_DATA: Dictionary = {
	"first_blood": {"name": "Первая кровь", "description": "Уничтожьте 10 врагов", "category": "progress", "rarity": "bronze", "reward": 100},
	"veteran": {"name": "Ветеран", "description": "Уничтожьте 500 врагов (всего)", "category": "progress", "rarity": "silver", "reward": 500},
	"mass_murderer": {"name": "Космический палач", "description": "Уничтожьте 2000 врагов (всего)", "category": "progress", "rarity": "gold", "reward": 2000},
	"survivor": {"name": "Выживальщик", "description": "Дойдите до волны 5", "category": "progress", "rarity": "bronze", "reward": 100},
	"asteroid_survivor": {"name": "Сквозь астероиды", "description": "Пройдите астероидное поле не получив урона", "category": "progress", "rarity": "gold", "reward": 2000},
	"laser_wall": {"name": "Лазерный ад", "description": "Пройдите лазерную полосу (волна 9)", "category": "progress", "rarity": "silver", "reward": 500},
	"conqueror": {"name": "Покоритель", "description": "Дойдите до босса волны 10", "category": "progress", "rarity": "silver", "reward": 500},
	"invincible": {"name": "Непобедимый", "description": "Пройдите все 10 волн", "category": "progress", "rarity": "gold", "reward": 2000},
	"boss_hunter": {"name": "Босс-хантер", "description": "Убейте 3 боссов (всего)", "category": "progress", "rarity": "silver", "reward": 500},
	"boss_master": {"name": "Повелитель боссов", "description": "Убейте 10 боссов (всего)", "category": "progress", "rarity": "gold", "reward": 2000},
	"high_scorer": {"name": "Живучий", "description": "Наберите 10 000 очков за одну игру", "category": "progress", "rarity": "silver", "reward": 500},
	"legendary_score": {"name": "Легендарный счёт", "description": "Наберите 50 000 очков за одну игру", "category": "progress", "rarity": "legendary", "reward": 5000},
	"collector": {"name": "Коллекционер", "description": "Разблокируйте все 3 корабля", "category": "ships", "rarity": "silver", "reward": 500},
	"phantom_ghost": {"name": "Призрак", "description": "Пройдите волну 5 на Фантоме, не получив урон", "category": "ships", "rarity": "gold", "reward": 2000},
	"goliath_wall": {"name": "Стена", "description": "Уничтожьте тараном 10 врагов на Голиафе за одну игру", "category": "ships", "rarity": "gold", "reward": 2000},
	"vanguard_speed": {"name": "Скорость", "description": "Пройдите волну 5 на Вангварде", "category": "ships", "rarity": "silver", "reward": 500},
	"triumvirate": {"name": "Триумвират", "description": "Выиграйте игру на каждом корабле", "category": "ships", "rarity": "legendary", "reward": 5000},
	"fashionista": {"name": "Модник", "description": "Разблокируйте все скины для любого корабля", "category": "ships", "rarity": "silver", "reward": 500},
	"machine_gunner": {"name": "Пулемётчик", "description": "Убейте 200 врагов лазером Mk2", "category": "weapons", "rarity": "bronze", "reward": 100},
	"armor_piercer": {"name": "Бронебой", "description": "Убейте 100 врагов пробивающим лазером", "category": "weapons", "rarity": "silver", "reward": 500},
	"plasma_master": {"name": "Плазма-мастер", "description": "Достигните 25 стаков плазмы 5 раз за одну игру", "category": "weapons", "rarity": "gold", "reward": 2000},
	"shotgunner": {"name": "Обойма", "description": "Убейте 300 врагов дробовиком любого типа (всего)", "category": "weapons", "rarity": "silver", "reward": 500},
	"rocketeer": {"name": "Реактивный", "description": "Убейте 100 врагов ракетами", "category": "weapons", "rarity": "silver", "reward": 500},
	"shockwave_master": {"name": "Шок и трепет", "description": "Активируйте ударную волну 20 раз", "category": "weapons", "rarity": "bronze", "reward": 100},
	"cocoon_user": {"name": "Неуязвимый", "description": "Заблокируйте урон Коконом Перерождения 10 раз", "category": "weapons", "rarity": "silver", "reward": 500},
	"nanobot_healer": {"name": "Нано-лечение", "description": "Исцелитесь наноботами 20 раз", "category": "weapons", "rarity": "bronze", "reward": 100},
	"phantom_dasher": {"name": "Призрачный рывок", "description": "Совершите 50 рывков за Фантома", "category": "mastery", "rarity": "silver", "reward": 500},
	"goliath_crusher": {"name": "Сокрушитель", "description": "Уничтожьте тараном Голиафа 50 врагов", "category": "mastery", "rarity": "gold", "reward": 2000},
	"homing_master": {"name": "Хомер", "description": "Уничтожьте 30 врагов самонаводящимися ракетами", "category": "mastery", "rarity": "silver", "reward": 500},
	"perfect_run": {"name": "Идеальный забег", "description": "Пройдите игру не получив урона (Вангвард)", "category": "mastery", "rarity": "legendary", "reward": 5000},
	"forsage_user": {"name": "Ускорение", "description": "Активируйте Forsage 20 раз", "category": "mastery", "rarity": "bronze", "reward": 100},
	"tactician": {"name": "Тактик", "description": "Активируйте Tactical Accelerator 20 раз", "category": "mastery", "rarity": "bronze", "reward": 100},
	"magnet": {"name": "Магнит", "description": "Соберите 35 аптечек", "category": "mastery", "rarity": "bronze", "reward": 100},
	"epic_crafter": {"name": "Эпик крафт", "description": "Соберите 3 эпических модуля", "category": "mastery", "rarity": "silver", "reward": 500},
	"saver": {"name": "Скупердяй", "description": "Накопите 10 000 кредитов", "category": "economy", "rarity": "bronze", "reward": 100},
	"oligarch": {"name": "Олигарх", "description": "Накопите 100 000 кредитов", "category": "economy", "rarity": "gold", "reward": 2000},
	"gambler": {"name": "Азартный", "description": "Откройте 10 сундуков", "category": "economy", "rarity": "bronze", "reward": 100},
	"spender": {"name": "Транжира", "description": "Откройте 50 сундуков", "category": "economy", "rarity": "gold", "reward": 2000},
	"carrier_slayer": {"name": "Один в поле воин", "description": "Убейте Носитель без получения урона", "category": "special", "rarity": "gold", "reward": 2000},
	"meat_grinder": {"name": "Мясорубка", "description": "Убейте 10 врагов за 3 секунды", "category": "special", "rarity": "gold", "reward": 2000},
	"combo_breaker": {"name": "Комбо-брейкер", "description": "Убейте 3 разных типа врагов за 2 секунды", "category": "special", "rarity": "silver", "reward": 500},
	"greedy": {"name": "Жадина", "description": "Откройте все модули и стили кораблей", "category": "special", "rarity": "legendary", "reward": 5000},
}

const ACHIEVEMENTS_TOTAL: int = 42


func unlock_achievement(achievement_id: String) -> bool:
	if achievements == null:
		achievements = {}
	if achievements.has(achievement_id) and achievements[achievement_id].get("unlocked", false):
		return false
	if not ACHIEVEMENT_DATA.has(achievement_id):
		print("[Achievement] Неизвестная ачивка: " + achievement_id)
		return false
	
	var ach_data = ACHIEVEMENT_DATA[achievement_id]
	achievements[achievement_id] = {"unlocked": true, "unlocked_at": Time.get_datetime_string_from_system()}
	
	var reward = ach_data.get("reward", 100)
	credits += reward
	credits_earned_total += reward
	save_game_async()
	print("[Achievement] Разблокировано: %s (+%d )" % [ach_data.get("name", achievement_id), reward])
	
	achievement_unlocked.emit(achievement_id, ach_data)
	
	return true


func is_achievement_unlocked(achievement_id: String) -> bool:
	if achievements == null:
		achievements = {}
	return achievements.has(achievement_id) and achievements[achievement_id].get("unlocked", false)


func get_achievement_count() -> int:
	if achievements == null:
		achievements = {}
	var count := 0
	for ach_id in ACHIEVEMENT_DATA:
		if achievements.has(ach_id) and achievements[ach_id].get("unlocked", false):
			count += 1
	return count


func get_achievement_data(ach_id: String) -> Dictionary:
	return ACHIEVEMENT_DATA.get(ach_id, {}).duplicate()


func get_all_achievement_ids() -> Array:
	return ACHIEVEMENT_DATA.keys()


func reset_tmp_counters() -> void:
	tmp_enemies_killed_total = 0
	tmp_bosses_killed_total = 0
	tmp_phantom_dashes = 0
	tmp_goliath_charge_kills = 0
	tmp_shockwave_used = 0
	tmp_forsage_procs = 0
	tmp_tactical_accelerator_procs = 0
	tmp_health_packs_collected = 0
	tmp_cocoon_shield_blocked = 0
	tmp_nanobots_healed = 0
	tmp_rocket_kills = 0
	tmp_homing_rocket_kills = 0
	tmp_shotgun_kills = 0
	tmp_laser_mk2_kills = 0
	tmp_laser_pierce_kills = 0
	tmp_damage_taken_in_game = 0
	tmp_asteroid_phase = false
	tmp_asteroid_damage_taken = false
	tmp_highest_wave = 0
	tmp_current_ship = "vanguard"
	tmp_carrier_kill_without_damage = false
	tmp_carrier_fight_damage_taken = false
	tmp_last_kill_time = 0.0
	tmp_kill_count_fast = 0
	tmp_kill_types_fast = []
	tmp_last_kill_fast_time = 0.0
	tmp_kill_count_total = 0
	tmp_plasma_stack_25_count = 0
	tmp_plasma_stack_value = 0
	tmp_laser_wall_survived = false
	tmp_game_won = false


func on_enemy_killed(weapon_id: String, enemy_name: String, is_boss: bool = false) -> void:
	tmp_enemies_killed_total += 1
	persistent_enemies_killed_total += 1
	
	if is_boss:
		tmp_bosses_killed_total += 1
		persistent_bosses_killed += 1
		on_boss_killed()
	
	match weapon_id:
		"laser_mk2": tmp_laser_mk2_kills += 1
		"laser_pierce": tmp_laser_pierce_kills += 1
		"rocket", "rocket_mk2", "rocket_homing", "rocket_nuke":
			tmp_rocket_kills += 1
			if weapon_id in ["rocket_mk2", "rocket_homing"]:
				tmp_homing_rocket_kills += 1
		"shotgun", "shotgun_whistle", "shotgun_pressure", "shotgun_heavy":
			tmp_shotgun_kills += 1
			persistent_shotgun_kills += 1
	
	if tmp_enemies_killed_total >= 10:
		unlock_achievement("first_blood")
	if persistent_enemies_killed_total >= 500:
		unlock_achievement("veteran")
	if persistent_enemies_killed_total >= 2000:
		unlock_achievement("mass_murderer")
	if tmp_laser_mk2_kills >= 200:
		unlock_achievement("machine_gunner")
	if tmp_laser_pierce_kills >= 100:
		unlock_achievement("armor_piercer")
	if persistent_shotgun_kills >= 300:
		unlock_achievement("shotgunner")
	if tmp_rocket_kills >= 100:
		unlock_achievement("rocketeer")
	if tmp_homing_rocket_kills >= 30:
		unlock_achievement("homing_master")
	if tmp_goliath_charge_kills >= 10:
		unlock_achievement("goliath_wall")
	if tmp_goliath_charge_kills >= 50:
		unlock_achievement("goliath_crusher")
	
	var now: float = Time.get_ticks_msec() / 1000.0
	# "Мясорубка": 10 убийств за 3 секунды от ПЕРВОГО убийства в серии
	if tmp_kill_count_fast == 0:
		# Начало новой серии
		tmp_last_kill_time = now
		tmp_kill_count_fast = 1
	elif now - tmp_last_kill_time <= 3.0:
		# Всё ещё в окне 3 секунд
		tmp_kill_count_fast += 1
		if tmp_kill_count_fast >= 10:
			unlock_achievement("meat_grinder")
	else:
		# Окно истекло — сбрасываем, начинаем новое с текущим убийством
		tmp_last_kill_time = now
		tmp_kill_count_fast = 1
	
	if now - tmp_last_kill_fast_time <= 2.0:
		if not enemy_name in tmp_kill_types_fast:
			tmp_kill_types_fast.append(enemy_name)
	else:
		tmp_kill_types_fast = [enemy_name]
	tmp_last_kill_fast_time = now
	if tmp_kill_types_fast.size() >= 3:
		unlock_achievement("combo_breaker")
	
	save_game_async()


func on_boss_killed() -> void:
	if persistent_bosses_killed >= 3:
		unlock_achievement("boss_hunter")
	if persistent_bosses_killed >= 10:
		unlock_achievement("boss_master")


func on_plasma_stack_reached_25() -> void:
	tmp_plasma_stack_25_count += 1
	tmp_plasma_stack_value = 0
	if tmp_plasma_stack_25_count >= 5:
		unlock_achievement("plasma_master")


func on_nuke_big_shot_used() -> void:
	var key := "_nuke_big_shot_count"
	var count: int = 0
	if achievements.has(key):
		count = int(achievements[key])
	count += 1
	achievements[key] = count
	if count >= 5:
		unlock_achievement("nuke_big_shot")


func on_wave_reached(wave: int) -> void:
	tmp_highest_wave = max(tmp_highest_wave, wave)
	if tmp_highest_wave >= 5:
		unlock_achievement("survivor")
	if tmp_highest_wave >= 10:
		unlock_achievement("conqueror")


func on_game_over(score: int) -> void:
	if score >= 10000:
		unlock_achievement("high_scorer")
	if score >= 50000:
		unlock_achievement("legendary_score")
	if tmp_asteroid_phase and not tmp_asteroid_damage_taken:
		unlock_achievement("asteroid_survivor")
	if tmp_current_ship == "vanguard" and tmp_highest_wave >= 5:
		unlock_achievement("vanguard_speed")
	if tmp_current_ship == "phantom" and tmp_highest_wave >= 5 and tmp_damage_taken_in_game == 0:
		unlock_achievement("phantom_ghost")
	if tmp_current_ship == "vanguard" and tmp_damage_taken_in_game == 0 and tmp_highest_wave >= 10:
		unlock_achievement("perfect_run")
	if tmp_carrier_kill_without_damage and not tmp_carrier_fight_damage_taken:
		unlock_achievement("carrier_slayer")
	if tmp_laser_wall_survived:
		unlock_achievement("laser_wall")
	if tmp_game_won:
		var won_key := "_won_with_" + tmp_current_ship
		achievements[won_key] = true
		if _check_triumvirate():
			unlock_achievement("triumvirate")


func on_laser_wall_completed() -> void:
	tmp_laser_wall_survived = true


func on_game_won() -> void:
	tmp_game_won = true
	unlock_achievement("invincible")
	var won_key := "_won_with_" + tmp_current_ship
	achievements[won_key] = true
	if _check_triumvirate():
		unlock_achievement("triumvirate")
	
	var beat_key := "_beat_difficulty_" + str(difficulty_level)
	achievements[beat_key] = true
	
	if difficulty_level == 0 and not 1 in difficulty_unlocked:
		difficulty_unlocked.append(1)
		save_game_async()
	if difficulty_level == 1 and not 2 in difficulty_unlocked:
		difficulty_unlocked.append(2)
		save_game_async()
	
	save_game_async()


func on_chest_opened() -> void:
	persistent_chests_opened += 1
	if persistent_chests_opened >= 10:
		unlock_achievement("gambler")
	if persistent_chests_opened >= 50:
		unlock_achievement("spender")
	save_game_async()


func on_credits_earned() -> void:
	if credits_earned_total >= 10000:
		unlock_achievement("saver")
	if credits_earned_total >= 100000:
		unlock_achievement("oligarch")


func on_achievement_progress_check() -> void:
	if unlocked_ships.size() >= 3:
		unlock_achievement("collector")
	for ship_id in ["vanguard", "phantom", "goliath"]:
		var entry = ship_skins.get(ship_id, {})
		var unlocked_arr = entry.get("unlocked", [])
		if unlocked_arr.size() >= 3:
			unlock_achievement("fashionista")
			break
	_check_greedy_achievement()
	_check_epic_crafter()


func _check_greedy_achievement() -> void:
	var all_unlocked := true
	var all_module_ids: Array = ALL_MODULE_IDS.duplicate()
	all_module_ids.append("laser")
	for mid in all_module_ids:
		if not owned_modules.has(mid) or int(owned_modules[mid]) <= 0:
			all_unlocked = false
			break
	if not all_unlocked:
		return
	for sid in SKIN_CHEST_POOL:
		var skin_parts: PackedStringArray = sid.split("_")
		if not is_skin_unlocked(skin_parts[1], int(skin_parts[2])):
			all_unlocked = false
			break
	if not all_unlocked:
		return
	if not ("phantom" in unlocked_ships and "goliath" in unlocked_ships):
		all_unlocked = false
	if all_unlocked:
		unlock_achievement("greedy")


func _check_epic_crafter() -> void:
	var epic_ids := ["diffusor", "cocoon_shield", "tactical_accelerator", "drone_epic", "drone_legendary"]
	var epic_count := 0
	for eid in epic_ids:
		if owned_modules.has(eid) and int(owned_modules[eid]) > 0:
			epic_count += 1
	if epic_count >= 3:
		unlock_achievement("epic_crafter")


func _check_triumvirate() -> bool:
	return achievements.get("_won_with_vanguard", false) \
		and achievements.get("_won_with_phantom", false) \
		and achievements.get("_won_with_goliath", false)


func on_player_damage_taken(weapon_id: String) -> void:
	tmp_damage_taken_in_game += 1
	tmp_carrier_fight_damage_taken = true
	if tmp_asteroid_phase:
		tmp_asteroid_damage_taken = true


func on_cocoon_shield_blocked() -> void:
	tmp_cocoon_shield_blocked += 1
	if tmp_cocoon_shield_blocked >= 10:
		unlock_achievement("cocoon_user")
