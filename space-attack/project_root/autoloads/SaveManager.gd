extends Node

var credits: int = 0
var damage_upgrade_level: int = 0
var fire_rate_upgrade_level: int = 0
var health_upgrade_level: int = 0
var high_score: int = 0

var owned_modules: Dictionary = {}
var equipped_modules: Dictionary = {
	"weapon": "",
	"defense": "",
	"utility": ""
}

# Система кораблей
var unlocked_ships: Array = ["vanguard"]
var current_ship: String = "vanguard"

const SHIP_COSTS: Dictionary = {
	"vanguard": 0,
	"phantom": 2000,
	"goliath": 5000
}

const SHIP_NAMES: Dictionary = {
	"vanguard": "Vanguard",
	"phantom": "Phantom",
	"goliath": "Goliath"
}

const MODULE_SLOT_BY_TYPE: Dictionary = {
	"weapon": "weapon",
	"defense": "defense",
	"utility": "utility"
}

const SAVE_PATH: String = "user://savegame.json"

const DEFAULT_MODULE_IDS: Array = [
	"laser", "shotgun", "rocket",
	"shield", "energy_shield", "reactive_armor",
	"magnet", "shockwave", "turbo", "nanobots"
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
			damage_upgrade_level = data.get("damage_upgrade_level", 0)
			fire_rate_upgrade_level = data.get("fire_rate_upgrade_level", 0)
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
		"equipped_modules": equipped_modules.duplicate(),
		"unlocked_ships": unlocked_ships.duplicate(),
		"current_ship": current_ship
	}


func save_game() -> void:
	var data = {
		"credits": credits,
		"damage_upgrade_level": damage_upgrade_level,
		"fire_rate_upgrade_level": fire_rate_upgrade_level,
		"health_upgrade_level": health_upgrade_level,
		"high_score": high_score,
		"owned_modules": owned_modules,
		"equipped_modules": equipped_modules,
		"unlocked_ships": unlocked_ships,
		"current_ship": current_ship
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
	owned_modules = {}
	for mid in DEFAULT_MODULE_IDS:
		owned_modules[mid] = 1
	equipped_modules = {
		"weapon": "laser",
		"defense": "shield",
		"utility": "magnet"
	}
	unlocked_ships = ["vanguard"]
	current_ship = "vanguard"


func is_ship_unlocked(ship_id: String) -> bool:
	return ship_id in unlocked_ships


func unlock_ship(ship_id: String) -> bool:
	if ship_id in unlocked_ships:
		return false
	unlocked_ships.append(ship_id)
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
	return true


func has_module(module_id: String) -> bool:
	return owned_modules.has(module_id) and int(owned_modules[module_id]) > 0


func equip_module(slot: String, module_id: String) -> bool:
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
	save_game()
