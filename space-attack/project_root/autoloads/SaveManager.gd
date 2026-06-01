extends Node

var credits: int = 0
var damage_upgrade_level: int = 0
var fire_rate_upgrade_level: int = 0
var health_upgrade_level: int = 0
var high_score: int = 0

# Словарь принадлежащих игроку модулей: {"shotgun": 1, "shield": 1, "magnet": 1}
var owned_modules: Dictionary = {}
# Словарь экипированных модулей по слотам: {"weapon": "shotgun", "defense": "shield", "utility": "magnet"}
var equipped_modules: Dictionary = {
	"weapon": "",
	"defense": "",
	"utility": ""
}

# Карта соответствия типа модуля и слота
const MODULE_SLOT_BY_TYPE: Dictionary = {
	"weapon": "weapon",
	"defense": "defense",
	"utility": "utility"
}

const SAVE_PATH: String = "user://savegame.json"


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
			damage_upgrade_level = data.get("damage_upgrade_level", 0)
			fire_rate_upgrade_level = data.get("fire_rate_upgrade_level", 0)
			health_upgrade_level = data.get("health_upgrade_level", 0)
			high_score = data.get("high_score", 0)

			# Загружаем модули. Если в сейве нет — инициализируем значениями по умолчанию
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

			# Гарантируем наличие всех слотов
			for slot in ["weapon", "defense", "utility"]:
				if not equipped_modules.has(slot):
					equipped_modules[slot] = ""
		else:
			set_defaults()
	else:
		set_defaults()
	return _to_dict()


func _to_dict() -> Dictionary:
	return {
		"credits": credits,
		"damage_upgrade_level": damage_upgrade_level,
		"fire_rate_upgrade_level": fire_rate_upgrade_level,
		"health_upgrade_level": health_upgrade_level,
		"high_score": high_score,
		"owned_modules": owned_modules.duplicate(),
		"equipped_modules": equipped_modules.duplicate()
	}


func save_game() -> void:
	var data = {
		"credits": credits,
		"damage_upgrade_level": damage_upgrade_level,
		"fire_rate_upgrade_level": fire_rate_upgrade_level,
		"health_upgrade_level": health_upgrade_level,
		"high_score": high_score,
		"owned_modules": owned_modules,
		"equipped_modules": equipped_modules
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.new().stringify(data))
		file.close()


func set_defaults() -> void:
	credits = 0
	damage_upgrade_level = 0
	fire_rate_upgrade_level = 0
	health_upgrade_level = 0
	high_score = 0
	# По умолчанию все базовые модули уже выдаются игроку
	owned_modules = {
		"shotgun": 1,
		"shield": 1,
		"magnet": 1,
		"shockwave": 1
	}
	equipped_modules = {
		"weapon": "shotgun",
		"defense": "shield",
		"utility": "magnet"
	}


# ---------- Система модулей ----------

# Добавляет модуль в инвентарь. Возвращает true, если модуль новый, иначе false.
func add_module(module_id: String) -> bool:
	if module_id == null or module_id.is_empty():
		return false
	if owned_modules.has(module_id):
		owned_modules[module_id] = int(owned_modules[module_id]) + 1
		return false
	owned_modules[module_id] = 1
	return true


# Проверяет, есть ли модуль у игрока
func has_module(module_id: String) -> bool:
	return owned_modules.has(module_id) and int(owned_modules[module_id]) > 0


# Экипирует модуль в указанный слот. Слот может быть: "weapon", "defense", "utility"
# Или может быть передан type модуля ("weapon"/"defense"/"utility") — слот подставится автоматически.
func equip_module(slot: String, module_id: String) -> bool:
	var target_slot := slot
	# Если передали type модуля вместо имени слота, найдём соответствующий слот
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


# Снимает модуль из слота
func unequip_module(slot: String) -> void:
	if equipped_modules.has(slot):
		equipped_modules[slot] = ""
		save_game()


# Возвращает id модуля, экипированного в слот (или пустую строку)
func get_equipped_in_slot(slot: String) -> String:
	if equipped_modules.has(slot):
		return equipped_modules[slot]
	return ""


# Возвращает список id модулей, принадлежащих игроку
func get_owned_module_ids() -> Array:
	return owned_modules.keys()


# Списывает кредиты. Возвращает true при успехе.
func spend_credits(amount: int) -> bool:
	if credits < amount:
		return false
	credits -= amount
	save_game()
	return true


# Начисляет кредиты
func add_credits(amount: int) -> void:
	credits += amount
	save_game()
