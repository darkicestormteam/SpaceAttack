extends Node

signal achievement_unlocked(achievement_id: String, achievement_data: Dictionary)

var credits: int = 0
var health_upgrade_level: int = 0
var high_score: int = 0

# Система сложностей
var difficulty_level: int = 0  # 0=Рекрут, 1=Ветеран, 2=Легенда
var difficulty_unlocked: Array = [0]  # какие сложности разблокированы

var owned_modules: Dictionary = {}
var equipped_modules: Dictionary = {
	"weapon": "",
	"defense": "",
	"utility": ""
}

# Система кораблей
var unlocked_ships: Array = ["vanguard"]
var current_ship: String = "vanguard"

# Система скинов: ship_id -> {"unlocked": [0], "current": 0}
var ship_skins: Dictionary = {}

# Покупки через Yandex Payments
var all_modules_purchased: bool = false  # все модули куплены
# Отложенный счёт для лидерборда (если SDK не был готов при смерти)
var pending_leaderboard_score: int = 0

# Система ачивок
var achievements: Dictionary = {}
var credits_earned_total: int = 0  # Общее количество заработанных кредитов

# === ПЕРСИСТЕНТНЫЕ СЧЁТЧИКИ (сохраняются между сессиями) ===
var persistent_enemies_killed_total: int = 0
var persistent_shotgun_kills: int = 0
var persistent_bosses_killed: int = 0
var persistent_modules_unlocked_count: int = 0  # количество уникальных модулей
var persistent_chests_opened: int = 0

# Трекинг для ачивок (сбрасывается при старте игры)
var tmp_enemies_killed_total: int = 0  # всего убито врагов за всё время
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
var tmp_damage_taken_in_game: int = 0  # урон в текущей игре
var tmp_asteroid_phase: bool = false  # в астероидной фазе
var tmp_asteroid_damage_taken: bool = false  # получен урон в астероидах
var tmp_highest_wave: int = 0
var tmp_current_ship: String = "vanguard"
var tmp_carrier_kill_without_damage: bool = false
var tmp_carrier_fight_damage_taken: bool = false
var tmp_last_kill_time: float = 0.0
var tmp_kill_count_fast: int = 0  # убийств подряд быстро
var tmp_kill_types_fast: Array = []  # типы врагов убитых быстро
var tmp_last_kill_fast_time: float = 0.0
var tmp_kill_count_total: int = 0
var tmp_plasma_stack_25_count: int = 0  # сколько раз достигли 25 стаков за игру
var tmp_plasma_stack_value: int = 0
var tmp_laser_wall_survived: bool = false
var tmp_game_won: bool = false

# === КОНСТАНТЫ ===

# Сколько уникальных модулей нужно открыть для ачивки "Жадина"
const GREEDY_MODULES_REQUIRED: int = 30

const SKIN_COUNT: int = 3

# Стоимость скинов (индекс скина -> цена)
const SKIN_COSTS: Dictionary = {
	0: 0,       # Стиль 1 — базовый, бесплатно
	1: 1000,    # Стиль 2 — 1000 
	2: 2500     # Стиль 3 — 2500 
}

const SHIP_COSTS: Dictionary = {
	"vanguard": 0,
	"phantom": 2000,
	"goliath": 5000
}

const SHIP_NAMES: Dictionary = {
	"vanguard": "Вангвард",
	"phantom": "Фантом",
	"goliath": "Голиаф"
}

const SKIN_NAMES: Dictionary = {
	0: "Стиль 1",
	1: "Стиль 2",
	2: "Стиль 3",
	3: "Стиль 4",
	4: "Стиль 5"
}

const MODULE_SLOT_BY_TYPE: Dictionary = {
	"weapon": "weapon",
	"defense": "defense",
	"utility": "utility"
}

const SAVE_PATH: String = "user://savegame.json"

# Пул всех модулей для ачивки "Жадина" (должен совпадать с MODULE_CHEST_POOL в Hangar.gd)
const ALL_MODULE_IDS: Array = [
	"laser_mk2", "laser_pierce", "laser_plasma",
	"shotgun", "shotgun_whistle", "shotgun_pressure", "shotgun_heavy",
	"rocket", "rocket_mk2", "rocket_homing", "rocket_nuke",
	"light_armor", "shield", "composite_armor", "forsage",
	"tactical_accelerator", "diffusor", "cocoon_shield",
	"drone", "drone_rare", "drone_epic", "drone_legendary",
	"shockwave", "turbo", "nanobots"
]

# Пул скинов для сундука скинов (базовые скины [0] уже есть у игрока)
const SKIN_CHEST_POOL: Array = [
	"skin_vanguard_1", "skin_vanguard_2",
	"skin_phantom_1", "skin_phantom_2",
	"skin_goliath_1", "skin_goliath_2"
]

const DEFAULT_MODULE_IDS: Array = [
	"laser"
]


func _ready() -> void:
	load_game()


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
			credits = data.get("credits", 0)
			health_upgrade_level = data.get("health_upgrade_level", 0)
			high_score = data.get("high_score", 0)

			var loaded_owned = data.get("owned_modules", {})
			if loaded_owned is Dictionary:
				owned_modules = (loaded_owned as Dictionary).duplicate()
			else:
				owned_modules = {}

			var loaded_equipped = data.get("equipped_modules", {})
			if loaded_equipped is Dictionary:
				equipped_modules = (loaded_equipped as Dictionary).duplicate()
			else:
				equipped_modules = {"weapon": "", "defense": "", "utility": ""}

			for slot in ["weapon", "defense", "utility"]:
				if not equipped_modules.has(slot):
					equipped_modules[slot] = ""

			for module_id in DEFAULT_MODULE_IDS:
				if not owned_modules.has(module_id):
					owned_modules[module_id] = 1

			# Корабли
			var loaded_unlocked = data.get("unlocked_ships", [])
			if loaded_unlocked is Array:
				unlocked_ships = loaded_unlocked.duplicate()
			if not unlocked_ships.has("vanguard"):
				unlocked_ships.append("vanguard")
			current_ship = data.get("current_ship", "vanguard")

			# Ачивки
			var loaded_achievements = data.get("achievements", {})
			if loaded_achievements is Dictionary:
				achievements = (loaded_achievements as Dictionary).duplicate()
			else:
				achievements = {}
			credits_earned_total = data.get("credits_earned_total", 0)

			# Сложности
			var loaded_diff_unlocked = data.get("difficulty_unlocked", [0])
			if loaded_diff_unlocked is Array and loaded_diff_unlocked.size() > 0:
				difficulty_unlocked = loaded_diff_unlocked.duplicate()
			else:
				difficulty_unlocked = [0]
			
			# Персистентные счётчики
			persistent_enemies_killed_total = data.get("persistent_enemies_killed_total", 0)
			persistent_shotgun_kills = data.get("persistent_shotgun_kills", 0)
			persistent_bosses_killed = data.get("persistent_bosses_killed", 0)
			persistent_modules_unlocked_count = data.get("persistent_modules_unlocked_count", 0)
			persistent_chests_opened = data.get("persistent_chests_opened", 0)

			# Покупки
			all_modules_purchased = data.get("all_modules_purchased", false)

			# Скины
			var loaded_skins = data.get("ship_skins", {})
			if loaded_skins is Dictionary:
				ship_skins = (loaded_skins as Dictionary).duplicate()
			else:
				ship_skins = {}
			_init_default_skins()
			# Миграция: удаляем из owned_modules скины, которые не разблокированы
			# (старый save мог содержать все скины из тестовой версии)
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

			# Пересчитываем persistent_modules_unlocked_count при загрузке
			_update_persistent_modules_count()
		else:
			set_defaults()
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
		# Добавляем базовый скин в owned_modules, чтобы он показывался в ModuleSelect
		var mid := "skin_%s_0" % ship_id
		if not owned_modules.has(mid):
			owned_modules[mid] = 1


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
	save_game()
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
	# Добавляем скин в owned_modules, чтобы он показывался в ModuleSelect
	var mid := "skin_%s_%d" % [ship_id, skin_index]
	if not owned_modules.has(mid):
		owned_modules[mid] = 1
	_update_persistent_modules_count()
	on_achievement_progress_check()
	save_game()
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


# Динамический подсчёт доступных скинов для корабля
# Сканирует папку res://data/modules/ на наличие skin_{ship_id}_{N}.tres
func get_skin_count(ship_id: String) -> int:
	var idx := 0
	var modules_dir := "res://data/modules/"
	while true:
		var tres_path := "%sskin_%s_%d.tres" % [modules_dir, ship_id, idx]
		if ResourceLoader.exists(tres_path):
			idx += 1
		else:
			break
	return max(idx, 1)  # минимум 1 (Стиль 1 по умолчанию)


func save_game() -> void:
	# Принудительное сохранение — кредиты фиксируются на диске немедленно.
	# Это гарантирует, что при досрочном выходе (например через Hangar/Рестарт/Alt+F4)
	# все заработанные в текущей сессии кредиты не пропадут.
	var data = {
		"credits": credits,
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
	}
	print("[SaveManager] Сохраняю difficulty_unlocked = " + str(difficulty_unlocked))

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.new().stringify(data))
		file.close()


func set_defaults() -> void:
	credits = 0
	health_upgrade_level = 0
	high_score = 0
	owned_modules = {}
	for mid in DEFAULT_MODULE_IDS:
		owned_modules[mid] = 1
	equipped_modules = {
		"weapon": "laser",
		"defense": "",
		"utility": ""
	}
	unlocked_ships = ["vanguard"]
	current_ship = "vanguard"
	_init_default_skins()


func is_ship_unlocked(ship_id: String) -> bool:
	return ship_id in unlocked_ships


func unlock_ship(ship_id: String) -> bool:
	if ship_id in unlocked_ships:
		return false
	unlocked_ships.append(ship_id)
	_update_persistent_modules_count()
	on_achievement_progress_check()
	save_game()
	return true


func select_ship(ship_id: String) -> bool:
	if not is_ship_unlocked(ship_id):
		return false
	current_ship = ship_id
	save_game()
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
	save_game()
	return true


# Пересчитывает количество уникальных открытых модулей (без учёта дубликатов)
func _update_persistent_modules_count() -> void:
	var count := 0
	for mid in owned_modules:
		# Считаем только модули, не скины и не стили
		if not mid.begins_with("skin_"):
			if int(owned_modules[mid]) > 0:
				count += 1
	persistent_modules_unlocked_count = count
	# Также считаем скины в общую сумму (каждый открытый скин на любом корабле)
	for ship_id in ["vanguard", "phantom", "goliath"]:
		var entry = ship_skins.get(ship_id, {})
		var unlocked_arr = entry.get("unlocked", [])
		for _skin_idx in unlocked_arr:
			count += 1
	# Но скины уже посчитаны через owned_modules, поэтому просто оставляем модули
	persistent_modules_unlocked_count = count


func has_module(module_id: String) -> bool:
	return owned_modules.has(module_id) and int(owned_modules[module_id]) > 0


func equip_module(slot: String, module_id: String) -> bool:
	# Обработка скинов: module_id = "skin_{ship}_{index}"
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
	save_game()
	return true


func unequip_module(slot: String) -> void:
	if equipped_modules.has(slot):
		equipped_modules[slot] = ""
		save_game()


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
	save_game()
	return true


func add_credits(amount: int) -> void:
	credits += amount
	credits_earned_total += amount
	on_credits_earned()
	save_game()


# Данные ачивок (id -> {name, description, category, rarity, reward})
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
	# "nuke_big_shot": {"name": "Ядерный залп", "description": "Активируйте big shot ракетницы nuke 5 раз", "category": "weapons", "rarity": "gold", "reward": 2000},
	"shockwave_master": {"name": "Шок и трепет", "description": "Активируйте ударную волну 20 раз", "category": "weapons", "rarity": "bronze", "reward": 100},
	"cocoon_user": {"name": "Неуязвимый", "description": "Заблокируйте урон Коконом Перерождения 10 раз", "category": "weapons", "rarity": "silver", "reward": 500},
	"nanobot_healer": {"name": "Нано-лечение", "description": "Исцелитесь наноботами 20 раз", "category": "weapons", "rarity": "bronze", "reward": 100},
	# "drone_army": {"name": "Дрон-армия", "description": "Имейте 3 активных дрона в одной игре", "category": "weapons", "rarity": "silver", "reward": 500},
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
	save_game()
	print("[Achievement] Разблокировано: %s (+%d )" % [ach_data.get("name", achievement_id), reward])
	
	# Оповещаем систему уведомлений
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

# === ТРИГГЕРЫ АЧИВОК ===

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
	
	# Убийство босса
	if is_boss:
		tmp_bosses_killed_total += 1
		persistent_bosses_killed += 1
		on_boss_killed()
	
	# Трекинг по оружию
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
	
	# Ачивка "Первая кровь"
	if tmp_enemies_killed_total >= 10:
		unlock_achievement("first_blood")
	
	# Ветеран и Космический палач — персистентные (многосессионные)
	if persistent_enemies_killed_total >= 500:
		unlock_achievement("veteran")
	if persistent_enemies_killed_total >= 2000:
		unlock_achievement("mass_murderer")
	
	# Ачивки по оружию
	if tmp_laser_mk2_kills >= 200:
		unlock_achievement("machine_gunner")
	if tmp_laser_pierce_kills >= 100:
		unlock_achievement("armor_piercer")
	
	# Обойма — персистентная (многосессионная)
	if persistent_shotgun_kills >= 300:
		unlock_achievement("shotgunner")
	
	if tmp_rocket_kills >= 100:
		unlock_achievement("rocketeer")
	if tmp_homing_rocket_kills >= 30:
		unlock_achievement("homing_master")
	
	# Ачивка "Goliath стена"
	if tmp_goliath_charge_kills >= 10:
		unlock_achievement("goliath_wall")
	if tmp_goliath_charge_kills >= 50:
		unlock_achievement("goliath_crusher")
	
	# Ачивка "Мясорубка" — 10 убийств за 3 секунды
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - tmp_last_kill_time <= 3.0:
		tmp_kill_count_fast += 1
	else:
		tmp_kill_count_fast = 1
	tmp_last_kill_time = now
	if tmp_kill_count_fast >= 10:
		unlock_achievement("meat_grinder")
	
	# Ачивка "Комбо-брейкер" — 3 разных типа за 2 секунды
	if now - tmp_last_kill_fast_time <= 2.0:
		if not enemy_name in tmp_kill_types_fast:
			tmp_kill_types_fast.append(enemy_name)
	else:
		tmp_kill_types_fast = [enemy_name]
	tmp_last_kill_fast_time = now
	if tmp_kill_types_fast.size() >= 3:
		unlock_achievement("combo_breaker")
	
	save_game()


func on_boss_killed() -> void:
	# Босс-хантер и Повелитель боссов
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
	# Считаем через tmp, потом проверка
	# Используем временный счётчик и сохраняем между сессиями через achievements
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
	
	# Ачивка "Сквозь астероиды"
	if tmp_asteroid_phase and not tmp_asteroid_damage_taken:
		unlock_achievement("asteroid_survivor")
	
	# Ачивка "Скорость" (Vanguard)
	if tmp_current_ship == "vanguard" and tmp_highest_wave >= 5:
		unlock_achievement("vanguard_speed")
	
	# Ачивка "Призрак" (Phantom без урона)
	if tmp_current_ship == "phantom" and tmp_highest_wave >= 5 and tmp_damage_taken_in_game == 0:
		unlock_achievement("phantom_ghost")
	
	# Ачивка "Идеальный забег" (Vanguard без урона)
	if tmp_current_ship == "vanguard" and tmp_damage_taken_in_game == 0 and tmp_highest_wave >= 10:
		unlock_achievement("perfect_run")
	
	# Ачивка "Один в поле воин" (Carrier без урона)
	if tmp_carrier_kill_without_damage and not tmp_carrier_fight_damage_taken:
		unlock_achievement("carrier_slayer")
	
	# Ачивка "Лазерный ад"
	if tmp_laser_wall_survived:
		unlock_achievement("laser_wall")
	
	# Ачивка "Непобедимый" — уже разблокирована в on_game_won(), здесь только проверяем триумвират
	if tmp_game_won:
		# Триумвират — сохраняем победу на корабле в achievements (персистентно)
		var won_key := "_won_with_" + tmp_current_ship
		achievements[won_key] = true
		if _check_triumvirate():
			unlock_achievement("triumvirate")


func on_laser_wall_completed() -> void:
	tmp_laser_wall_survived = true


func on_game_won() -> void:
	tmp_game_won = true
	# Непобедимый
	unlock_achievement("invincible")
	# Триумвират — сохраняем победу на корабле в achievements (персистентно)
	var won_key := "_won_with_" + tmp_current_ship
	achievements[won_key] = true
	if _check_triumvirate():
		unlock_achievement("triumvirate")
	
	# Сохраняем флаг победы на текущей сложности
	var beat_key := "_beat_difficulty_" + str(difficulty_level)
	achievements[beat_key] = true
	
	# Разблокировка сложностей: Рекрут -> Ветеран -> Легенда
	if difficulty_level == 0 and not 1 in difficulty_unlocked:
		difficulty_unlocked.append(1)
		save_game()
		print("[Difficulty] Ветеран разблокирован!")
	if difficulty_level == 1 and not 2 in difficulty_unlocked:
		difficulty_unlocked.append(2)
		save_game()
		print("[Difficulty] Легенда разблокирована!")
	
	save_game()


func on_chest_opened() -> void:
	persistent_chests_opened += 1
	if persistent_chests_opened >= 10:
		unlock_achievement("gambler")
	if persistent_chests_opened >= 50:
		unlock_achievement("spender")
	save_game()


func on_credits_earned() -> void:
	if credits_earned_total >= 10000:
		unlock_achievement("saver")
	if credits_earned_total >= 100000:
		unlock_achievement("oligarch")


func on_achievement_progress_check() -> void:
	# Коллекционер — все 3 корабля
	if unlocked_ships.size() >= 3:
		unlock_achievement("collector")
	
	# Модник — все скины для любого корабля
	for ship_id in ["vanguard", "phantom", "goliath"]:
		var entry = ship_skins.get(ship_id, {})
		var unlocked_arr = entry.get("unlocked", [])
		if unlocked_arr.size() >= 3:
			unlock_achievement("fashionista")
			break
	
	# Жадина — открыть все модули и скины кораблей
	_check_greedy_achievement()
	
	# Эпик крафт — 3 эпических модуля
	_check_epic_crafter()


func _check_greedy_achievement() -> void:
	# Проверяем, открыты ли все модули из пула + все скины из пула + оба доп. корабля
	var all_unlocked := true
	
	# Проверяем все модули ALL_MODULE_IDS + базовый laser
	var all_module_ids: Array = ALL_MODULE_IDS.duplicate()
	all_module_ids.append("laser")
	for mid in all_module_ids:
		if not owned_modules.has(mid) or int(owned_modules[mid]) <= 0:
			all_unlocked = false
			break
	
	if not all_unlocked:
		return
	
	# Проверяем все скины из пула SKIN_CHEST_POOL
	for sid in SKIN_CHEST_POOL:
		var skin_parts: PackedStringArray = sid.split("_")
		if not is_skin_unlocked(skin_parts[1], int(skin_parts[2])):
			all_unlocked = false
			break
	
	if not all_unlocked:
		return
	
	# Проверяем корабли
	if not ("phantom" in unlocked_ships and "goliath" in unlocked_ships):
		all_unlocked = false
	
	if all_unlocked:
		unlock_achievement("greedy")


func _check_epic_crafter() -> void:
	# Эпические модули: diffusor, cocoon_shield, tactical_accelerator, drone_epic, drone_legendary
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
