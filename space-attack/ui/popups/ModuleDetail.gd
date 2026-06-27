extends CanvasLayer

signal module_confirmed(module_id: String)
signal detail_closed

const MODULE_BUTTON_SCENE: PackedScene = preload("res://ui/popups/ModuleButton.tscn")

var _module_id: String = ""
var _slot: String = ""
var _module_res: Resource = null
var _vis_button: ModuleButton = null

var MODULE_STATS: Dictionary = {
	# WEAPONS
	"laser": {
		"name": "Лазер", "type": "weapon", "rarity": "common",
		"damage": 10, "fire_rate": "0.2 сек", "pellets": 1,
		"special": "",
		"description": "Стандартное лазерное оружие. Быстрая стрельба, базовый урон."
	},
	"laser_mk2": {
		"name": "Двойной Лазер Mk.II", "type": "weapon", "rarity": "rare",
		"damage": 8, "fire_rate": "0.22 сек", "pellets": 2,
		"special": "Два расходящихся луча. Эффективно против групп.",
		"description": "Улучшенная версия лазера, стреляющая двумя расходящимися лучами."
	},
	"laser_pierce": {
		"name": "Пронзающий Лазер", "type": "weapon", "rarity": "epic",
		"damage": 15, "fire_rate": "0.25 сек", "pellets": 1,
		"special": "Пронзает всех врагов на линии.",
		"description": "Мощный лазер, пронзающий врагов насквозь."
	},
	"laser_plasma": {
		"name": "Самонав. Плазма", "type": "weapon", "rarity": "legendary",
		"damage": 20, "fire_rate": "0.4 сек", "pellets": 1,
		"special": "Самонаведение на врага. Каждое попадание +2% скорострельности (до +100%, сброс через 2 сек).",
		"description": "Плазма с самонаведением. Ускоряется с каждым попаданием."
	},
	"shotgun": {
		"name": "Дробовик", "type": "weapon", "rarity": "common",
		"damage": 5, "fire_rate": "0.5 сек", "pellets": 7,
		"special": "Широкий веер разлёта.",
		"description": "Дробовик с широким веером разлёта дроби."
	},
	"shotgun_whistle": {
		"name": "Дробовик Mk.II", "type": "weapon", "rarity": "rare",
		"damage": 6, "fire_rate": "0.35 сек", "pellets": 5,
		"special": "Веер 45°. Высокая скорость пуль.",
		"description": "Быстрый дробовик с улучшенной скорострельностью."
	},
	"shotgun_pressure": {
		"name": "Дробовик Пробивной", "type": "weapon", "rarity": "epic",
		"damage": 15, "fire_rate": "0.6 сек", "pellets": 3,
		"special": "Узкий веер 20°. Каждая дробина пробивает врагов.",
		"description": "Тяжёлый дробовик с пробивными снарядами."
	},
	"shotgun_heavy": {
		"name": "Дробовик Картечь", "type": "weapon", "rarity": "legendary",
		"damage": 8, "fire_rate": "0.5 сек", "pellets": 5,
		"special": "Веер 70°. При убийстве врага вылетает 6 дополнительных пуль.",
		"description": "Легендарный дробовик с эффектом картечи при убийстве."
	},
	"rocket": {
		"name": "Ракетница", "type": "weapon", "rarity": "common",
		"damage": 30, "fire_rate": "1.0 сек", "pellets": 1,
		"special": "",
		"description": "Ракета, летящая прямо. Медленная стрельба."
	},
	"rocket_mk2": {
		"name": "Ракетница Mk.II", "type": "weapon", "rarity": "rare",
		"damage": 30, "fire_rate": "1.0 сек", "pellets": 1,
		"special": "Самонаведение на врага.",
		"description": "Ракеты с самонаведением на ближайшую цель."
	},
	"rocket_homing": {
		"name": "Самонав. Ракеты", "type": "weapon", "rarity": "epic",
		"damage": 30, "fire_rate": "1.0 сек", "pellets": 1,
		"special": "Активная способность: залп 5 ракет, перезарядка 10 секунд.",
		"description": "Ракеты с самонаведением на цель."
	},
	"rocket_nuke": {
		"name": "Шторм ракет", "type": "weapon", "rarity": "legendary",
		"damage": 40, "fire_rate": "1.0 сек", "pellets": 3,
		"special": "Обычный залп: 3 ракеты. Каждые 4 сек — усиленный залп: 5 ракет.",
		"description": "Массовый ракетный залп с периодическим усилением."
	},
	# DEFENSE
	"light_armor": {
		"name": "Лёгкая Броня", "type": "defense", "rarity": "common",
		"special": "+1 HP к максимальному здоровью. Постоянный эффект.",
		"description": "Увеличивает запас здоровья на 1."
	},
	"shield": {
		"name": "Щит", "type": "defense", "rarity": "common",
		"special": "Прочность 5. После разрушения не восстанавливается до конца раунда.",
		"description": "Стандартный силовой щит, поглощающий урон."
	},
	"shield_new": {
		"name": "Силовой Щит", "type": "defense", "rarity": "rare",
		"special": "Прочность 10. После разрушения не восстанавливается до конца раунда.",
		"description": "Улучшенный силовой щит с повышенной прочностью."
	},
	"energy_shield": {
		"name": "Энергощит", "type": "defense", "rarity": "epic",
		"special": "Поглощает урон и конвертирует в кредиты.",
		"description": "Поглощает урон и превращает его в кредиты."
	},
	"composite_armor": {
		"name": "Композитная Броня", "type": "defense", "rarity": "rare",
		"special": "Каждый 3-й удар по вам полностью блокируется.",
		"description": "Композитная броня с периодической блокировкой ударов."
	},
	"forsage": {
		"name": "Форсаж", "type": "defense", "rarity": "rare",
		"special": "При получении урона: скорость +50% на 2 сек.",
		"description": "Ускоряет корабль при получении урона."
	},
	"tactical_accelerator": {
		"name": "Тактический Ускоритель", "type": "defense", "rarity": "epic",
		"special": "При получении урона: скорость выстрелов +30% на 3 сек.",
		"description": "Повышает скорострельность после получения урона."
	},
	"diffusor": {
		"name": "Диффузор", "type": "defense", "rarity": "epic",
		"special": "100% шанс нанести 10 урона случайному врагу в радиусе 200.",
		"description": "С шансом контратакует врагов при получении урона."
	},
	"cocoon_shield": {
		"name": "Кокон возрождения", "type": "defense", "rarity": "legendary",
		"special": "Блокирует 1 попадание (КД 25 сек). При смерти — возрождение с 50% HP (один раз).",
		"description": "Легендарный щит с блоком и возрождением."
	},
	# UTILITY
	"turbo": {
		"name": "Турбо-ускоритель", "type": "utility", "rarity": "rare",
		"special": "Скорость +30%. Постоянный эффект.",
		"description": "Постоянно увеличивает скорость корабля."
	},
	"nanobots": {
		"name": "Нано-роботы", "type": "utility", "rarity": "epic",
		"special": "Автовосстановление +1 HP каждые 20 сек.",
		"description": "Медленная регенерация здоровья."
	},
	"shockwave": {
		"name": "Импульсная Волна", "type": "utility", "rarity": "epic",
		"special": "Активируемая ударная волна. КД 8 сек.",
		"description": "Активируемая ударная волна, отбрасывающая врагов."
	},
	"magnet": {
		"name": "Магнит", "type": "utility", "rarity": "common",
		"special": "Притягивает кредиты и ресурсы с большого расстояния.",
		"description": "Увеличивает радиус сбора ресурсов."
	},
	"drone": {
		"name": "Дрон", "type": "utility", "rarity": "common",
		"special": "1 вспомогательный дрон, стреляющий лазерами.",
		"description": "Призывает дрона для помощи в бою."
	},
	"drone_rare": {
		"name": "Дроны-близнецы", "type": "utility", "rarity": "rare",
		"special": "2 дрона с усиленными лазерами.",
		"description": "Пара улучшенных боевых дронов."
	},
	"drone_epic": {
		"name": "Боевые дроны", "type": "utility", "rarity": "epic",
		"special": "2 дрона. Копируют ваше оружие.",
		"description": "Элитные дроны с копированием оружия."
	},
	"drone_legendary": {
		"name": "Эскадрилья", "type": "utility", "rarity": "legendary",
		"special": "3 дрона. Копируют оружие. Перехватывают вражеские снаряды.",
		"description": "Легендарные дроны с перехватом снарядов."
	},
	# SKINS — данные из res://data/modules/skin_*.tres
	"skin_vanguard_0": {
		"name": "Вангвард", "type": "skin", "rarity": "common",
		"special": "Скорость - 400 м/с
		Здоровье - 3 HP
				Способность - нет",
		"description": "Классический корабль-разведчик. Лёгкий, манёвренный, надёжный как сталь. С него начинается путь каждого пилота."
	},
	"skin_vanguard_1": {
		"name": "Вангвард МКII", "type": "skin", "rarity": "rare",
		"special": "Скорость - 420 м/с
		Здоровье - 3 HP
		Множитель скорости атаки +10%
		Способность - нет",
		"description": "Модернизированная версия с усиленным корпусом и форсированными двигателями. Создан для тех, кто не боится идти вперёд."
	},
	"skin_vanguard_2": {
		"name": "Вангвард МКIII", "type": "skin", "rarity": "rare",
		"special": "Скорость - 430 м/с
		Здоровье - 4 HP
		Множитель скорости атаки +20%
		Способность - нет",
		"description": "Флагман серии Вангвард. Продвинутая аэродинамика, реактивные ускорители и система распределения энергии — идеальный баланс скорости и огня."
	},
	"skin_phantom_0": {
		"name": "Фантом", "type": "skin", "rarity": "rare",
		"special": "Скорость - 400 м/с
		Здоровье - 3 HP
		Способность - Рывок, телепортирует корабль на небольшое расстояние.
		Кулдаун рывка - 3 сек.
		Неуязвимость при рывке.",
		"description": "Призрачный истребитель, созданный по технологиям маскировки. Его силуэт сложно засечь на радарах — враг видит лишь тень перед ударом."
	},
	"skin_phantom_1": {
		"name": "Фантом ярость", "type": "skin", "rarity": "rare",
		"special": "Скорость - 430 м/с
		Здоровье - 3 HP
		Множитель скорости атаки +20%
		Способность - Рывок, телепортирует корабль на небольшое расстояние.
		Кулдаун рывка - 3 сек.
		Неуязвимость при рывке.",
		"description": "Модификация с перегруженными контурами питания. Вспышки ярости плазмы вырываются из двигателей, когда корабль уходит в рывок."
	},
	"skin_phantom_2": {
		"name": "Фантом пронзания", "type": "skin", "rarity": "epic",
		"special": "Скорость - 440 м/с
		Здоровье - 4 HP
		Множитель скорости атаки +30%
		Способность - Рывок, телепортирует корабль на небольшое расстояние.
		Кулдаун рывка - 3 сек.
		Неуязвимость при рывке.",
		"description": "Легендарный прототип с экспериментальным фазовым двигателем. Корпус покрыт нано-чешуёй, рассеивающей вражеские лазеры. Говорят, этот корабль способен пробить само пространство."
	},
	"skin_goliath_0": {
		"name": "Голиаф", "type": "skin", "rarity": "rare",
		"special": "Скорость - 280 м/с
		Здоровье - 4 HP
		Множитель скорости атаки +10%
		Способность - Рывок со щитом, резко летит вперед активируя щит, который поглащает урон и так же наносит урон противникам.
		Кулдаун рывка - 6 сек.
		Длительность рывка - 0.5 сек.
		Урон противникам - 60 ед.
		Неуязвимость при рывке.
		Пассивная способность - композитная броня позволяет игнорировать урон он вражеских Скаутов",
		"description": "Тяжёлый штурмовик, броня которого выдержит прямое попадание из плазменной пушки. Медленный, но неудержимый, как таран."
	},
	"skin_goliath_1": {
		"name": "Голиаф Ярости", "type": "skin", "rarity": "rare",
		"special": "Скорость - 290 м/с
		Здоровье - 5 HP
		Множитель скорости атаки +20%
		Способность - Рывок со щитом, резко летит вперед активируя щит, который поглащает урон и так же наносит урон противникам.
		Кулдаун рывка - 6 сек.
		Длительность рывка - 0.5 сек.
		Урон противникам - 60 ед.
		Неуязвимость при рывке.
		Пассивная способность - композитная броня позволяет игнорировать урон он вражеских Скаутов, так же при столкновении они не наносят урон.",
		"description": "Усиленная версия с дополнительными слоями композитной брони и системой аварийного ускорения. Чем сильнее бьют — тем злее он становится."
	},
	"skin_goliath_2": {
		"name": "Голиаф Императора", "type": "skin", "rarity": "epic",
		"special": "Скорость - 300 м/с
		Здоровье - 6 HP
		Множитель скорости атаки +30%
		Способность - Рывок со щитом, резко летит вперед активируя щит, который поглащает урон и так же наносит урон противникам.
		Кулдаун рывка - 6 сек.
		Длительность рывка - 0.5 сек.
		Урон противникам - 60 ед.
		Неуязвимость при рывке.
		Пассивная способность - композитная броня позволяет игнорировать урон он вражеских Скаутов, так же при столкновении они не наносят урон.",
		"description": "Личный флагманский корабль, достойный Императора. Композитные накладки, церемониальная гравировка на броне и двигатели, ревущие как раненый зверь. Его появление на поле боя меняет исход сражения."
	}
}

const RARITY_COLORS: Dictionary = {
	"common": Color(1, 1, 1, 1),
	"rare": Color(0.3, 0.6, 1, 1),
	"epic": Color(0.7, 0.3, 1, 1),
	"legendary": Color(1, 0.7, 0.1, 1)
}

const RARITY_NAMES: Dictionary = {
	"common": "Обычный",
	"rare": "Редкий",
	"epic": "Эпический",
	"legendary": "Легендарный"
}

var FONT_SIZE: int = 20


func _disable_wrap(lbl: Label) -> void:
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	lbl.add_theme_constant_override("word_wrap_enabled", 0)


func _enable_smart_wrap(lbl: Label) -> void:
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_constant_override("word_wrap_enabled", 3)


@onready var visual_container: Control = $Panel/MarginContainer/VBoxContainer/Header/VisualContainer
@onready var name_label: Label = $Panel/MarginContainer/VBoxContainer/Header/InfoVBox/NameLabel
@onready var rarity_label: Label = $Panel/MarginContainer/VBoxContainer/Header/InfoVBox/RarityTypeHBox/RarityLabel
@onready var type_label: Label = $Panel/MarginContainer/VBoxContainer/Header/InfoVBox/RarityTypeHBox/TypeLabel
@onready var description_label: Label = $Panel/MarginContainer/VBoxContainer/DescriptionLabel
@onready var stats_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/StatsContainer
@onready var special_label: Label = $Panel/MarginContainer/VBoxContainer/SpecialLabel
@onready var select_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonHBox/SelectButton
@onready var cancel_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonHBox/CancelButton


func _ready() -> void:
	select_button.pressed.connect(_on_select_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	_disable_wrap(name_label)
	_disable_wrap(rarity_label)
	_disable_wrap(type_label)
	_enable_smart_wrap(description_label)
	_enable_smart_wrap(special_label)


func setup(module_id: String, slot: String) -> void:
	_module_id = module_id
	_slot = slot
	_load_module_data()
	_setup_visual()
	_update_ui()


func _setup_visual() -> void:
	_vis_button = MODULE_BUTTON_SCENE.instantiate()
	_vis_button.custom_minimum_size = Vector2(128, 128)
	_vis_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in visual_container.get_children():
		child.queue_free()
	visual_container.add_child(_vis_button)
	_vis_button.setup(_module_id)


func _get_dict_val(d: Dictionary, key: String, default_val = null):
	if d.has(key):
		return d[key]
	return default_val


func _resource_get_str(res: Resource, key: String, default_val: String) -> String:
	if res == null:
		return default_val
	var val = res.get(key)
	if val == null:
		return default_val
	return str(val)


func _load_module_data() -> void:
	var path: String = "res://data/modules/%s.tres" % _module_id
	if ResourceLoader.exists(path):
		_module_res = load(path)
	if not MODULE_STATS.has(_module_id) and _module_res != null:
		var entry: Dictionary = {
			"name": _resource_get_str(_module_res, "name", _module_id),
			"type": _resource_get_str(_module_res, "type", "weapon"),
			"rarity": _resource_get_str(_module_res, "rarity", "common"),
			"description": _resource_get_str(_module_res, "description", ""),
			"special": "",
			"damage": null,
			"fire_rate": "",
			"pellets": 1
		}
		MODULE_STATS[_module_id] = entry


func _get_stats() -> Dictionary:
	if MODULE_STATS.has(_module_id):
		return MODULE_STATS[_module_id]
	return {}


func _update_ui() -> void:
	var stats: Dictionary = _get_stats()
	if stats.is_empty():
		return

	var display_name: String = _get_dict_val(stats, "name", _module_id)
	name_label.text = display_name
	name_label.add_theme_font_size_override("font_size", FONT_SIZE)

	var rarity: String = _get_dict_val(stats, "rarity", "common")
	var rarity_color: Color = _get_dict_val(RARITY_COLORS, rarity, Color.WHITE)
	var rarity_name: String = _get_dict_val(RARITY_NAMES, rarity, rarity)
	rarity_label.text = rarity_name
	rarity_label.add_theme_color_override("font_color", rarity_color)
	rarity_label.add_theme_font_size_override("font_size", FONT_SIZE)

	var type_map: Dictionary = {"weapon": "Оружие", "defense": "Защита", "utility": "Утилита"}
	var type_str: String = _get_dict_val(stats, "type", "")
	type_label.text = _get_dict_val(type_map, type_str, "")
	type_label.add_theme_font_size_override("font_size", FONT_SIZE)

	description_label.text = _get_dict_val(stats, "description", "")
	description_label.add_theme_font_size_override("font_size", FONT_SIZE)

	_build_stats(stats)

	var special: String = _get_dict_val(stats, "special", "")
	special_label.text = special
	special_label.visible = not special.is_empty()
	special_label.add_theme_font_size_override("font_size", FONT_SIZE)


func _build_stats(stats: Dictionary) -> void:
	for child in stats_container.get_children():
		child.queue_free()

	var type: String = _get_dict_val(stats, "type", "")

	if type == "weapon":
		var dmg = stats.get("damage")
		_add_stat("Урон", str(dmg) if dmg != null else "?")
		_add_stat("Задержка", _get_dict_val(stats, "fire_rate", "?"))
		var pellets = _get_dict_val(stats, "pellets", 1)
		_add_stat("Снарядов", str(pellets))

	elif type == "defense":
		match _module_id:
			"light_armor": _add_stat("Эффект", "+1 HP")
			"shield": _add_stat("Эффект", "Поглощение 5 ед.")
			"shield_new": _add_stat("Эффект", "Поглощение 10 ед.")
			"energy_shield": _add_stat("Эффект", "Конвертация в кредиты")
			"composite_armor": _add_stat("Эффект", "Блок каждый 4-й удар")
			"forsage":
				_add_stat("Скорость", "+50%")
				_add_stat("Длительность", "2 сек")
			"tactical_accelerator":
				_add_stat("Скорострельность", "+30%")
				_add_stat("Длительность", "3 сек")
			"diffusor":
				_add_stat("Шанс", "50%")
				_add_stat("Урон контратаки", "10")
			"cocoon_shield":
				_add_stat("Блок", "1 попадание")
				_add_stat("КД", "25 сек")
				_add_stat("Возрождение", "50% HP")

	elif type == "utility":
		match _module_id:
			"turbo": _add_stat("Скорость", "+30%")
			"nanobots": _add_stat("Регенерация", "1 HP / 15 сек")
			"shockwave": _add_stat("КД", "8 сек")
			"magnet": _add_stat("Радиус", "Большой")
			"drone": _add_stat("Дронов", "1")
			"drone_rare": _add_stat("Дронов", "2")
			"drone_epic":
				_add_stat("Дронов", "2")
				_add_stat("Копирует оружие", "Да")
			"drone_legendary":
				_add_stat("Дронов", "3")
				_add_stat("Копирует оружие", "Да")
				_add_stat("Перехват", "Да")


func _add_stat(label_text: String, value: String) -> void:
	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var lbl := Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	lbl.add_theme_font_size_override("font_size", FONT_SIZE)
	_disable_wrap(lbl)

	var val := Label.new()
	val.text = value
	val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	val.add_theme_font_size_override("font_size", FONT_SIZE)
	val.custom_minimum_size = Vector2(80, 0)
	_disable_wrap(val)

	hbox.add_child(lbl)
	hbox.add_child(val)
	stats_container.add_child(hbox)


func _on_select_pressed() -> void:
	module_confirmed.emit(_module_id)
	queue_free()


func _on_cancel_pressed() -> void:
	detail_closed.emit()
	queue_free()
