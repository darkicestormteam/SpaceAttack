extends Node

var credits: int = 0
var damage_upgrade_level: int = 0
var fire_rate_upgrade_level: int = 0
var health_upgrade_level: int = 0
var high_score: int = 0

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
		"high_score": high_score
	}


func save_game() -> void:
	var data = {
		"credits": credits,
		"damage_upgrade_level": damage_upgrade_level,
		"fire_rate_upgrade_level": fire_rate_upgrade_level,
		"health_upgrade_level": health_upgrade_level,
		"high_score": high_score
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
