extends Node
class_name Constants

# ============================================================
# КОНСТАНТЫ СЛОЖНОСТИ
# ============================================================

# Идентификаторы уровней сложности
const DIFFICULTY_RECRUIT: int = 0
const DIFFICULTY_VETERAN: int = 1
const DIFFICULTY_LEGEND: int = 2

# Все параметры баланса для каждой сложности
const DIFFICULTY_CONFIG: Dictionary = {
	DIFFICULTY_RECRUIT: {
		"display_name": "Рекрут",
		"description": "Стандартный режим. Идеально для начала!",
		
		# Враги
		"enemy_hp_multiplier": 1.0,
		"projectile_speed_multiplier": 1.0,
		
		# Спец-фазы (секунды)
		"asteroid_phase_duration": 15.0,
		"laser_wave_duration": 30.0,
		
		# Боссы
		"boss_cooldown_reduction": 0.0,
		"boss_hp_multiplier": 1.0,
		
		# Ресурсы
		"credits_multiplier": 1.0,
		"score_multiplier": 1.0,
	},
	
	DIFFICULTY_VETERAN: {
		"display_name": "Ветеран",
		"description": "Повышенная сложность для опытных пилотов.",
		
		"enemy_hp_multiplier": 1.5,
		"projectile_speed_multiplier": 1.1,
		
		"asteroid_phase_duration": 20.0,
		"laser_wave_duration": 40.0,
		
		"boss_cooldown_reduction": 0.2,
		"boss_hp_multiplier": 1.5,
		
		"credits_multiplier": 1.5,
		"score_multiplier": 1.5,
	},
	
	DIFFICULTY_LEGEND: {
		"display_name": "Легенда",
		"description": "Максимальный вызов для настоящих легенд.",
		
		"enemy_hp_multiplier": 2.0,
		"projectile_speed_multiplier": 1.15,
		
		"asteroid_phase_duration": 30.0,
		"laser_wave_duration": 50.0,
		
		"boss_cooldown_reduction": 0.3,
		"boss_hp_multiplier": 2.0,
		
		"credits_multiplier": 2.0,
		"score_multiplier": 2.0,
	},
}


# Вспомогательная функция: получить конфиг для текущей сложности
static func get_config() -> Dictionary:
	var tree = Engine.get_main_loop()
	if tree == null or tree.root == null:
		return DIFFICULTY_CONFIG[DIFFICULTY_RECRUIT]
	var sm = tree.root.get_node_or_null("SaveManager")
	var difficulty = DIFFICULTY_RECRUIT
	if sm != null and "difficulty_level" in sm:
		difficulty = sm.difficulty_level
	return DIFFICULTY_CONFIG.get(difficulty, DIFFICULTY_CONFIG[DIFFICULTY_RECRUIT])


# Вспомогательная функция: получить значение по ключу из конфига сложности
static func get_value(key: String, default = null):
	var cfg := get_config()
	return cfg.get(key, default)


# Короткие хелперы для самых частых параметров
static func enemy_hp_mult() -> float:
	return float(get_value("enemy_hp_multiplier", 1.0))

static func projectile_speed_mult() -> float:
	return float(get_value("projectile_speed_multiplier", 1.0))

static func credits_mult() -> float:
	return float(get_value("credits_multiplier", 1.0))

static func score_mult() -> float:
	return float(get_value("score_multiplier", 1.0))

static func boss_hp_mult() -> float:
	return float(get_value("boss_hp_multiplier", 1.0))

static func boss_cooldown_reduction() -> float:
	return float(get_value("boss_cooldown_reduction", 0.0))
