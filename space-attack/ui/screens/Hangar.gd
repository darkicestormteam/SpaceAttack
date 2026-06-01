extends Control

# Стоимость открытия сундука и компенсация за дубликат
const CHEST_COST: int = 500
const CHEST_DUPLICATE_COMPENSATION: int = 100

# Возможные модули в сундуке
const CHEST_POOL: Array = ["shotgun", "shield", "magnet"]

# Пути к ресурсам модулей
const MODULE_PATHS: Dictionary = {
	"shotgun": "res://data/modules/shotgun.tres",
	"shield": "res://data/modules/shield.tres",
	"magnet": "res://data/modules/magnet.tres"
}

# Сцены popups
const MODULE_SELECT_SCENE: PackedScene = preload("res://ui/popups/ModuleSelect.tscn")
const CHEST_OPEN_SCENE: PackedScene = preload("res://ui/popups/ChestOpen.tscn")

@onready var credits_label: Label = %CreditsLabel
@onready var high_score_label: Label = %HighScoreLabel
@onready var play_button: Button = %PlayButton
@onready var shop_button: Button = %ShopButton
@onready var quit_button: Button = %QuitButton
@onready var weapon_slot: Button = %WeaponSlot
@onready var defense_slot: Button = %DefenseSlot
@onready var utility_slot: Button = %UtilitySlot
@onready var chest_button: Button = %ChestButton
@onready var chest_hint_label: Label = %ChestHintLabel


func _ready() -> void:
	SaveManager.load_game()
	update_ui()

	play_button.pressed.connect(_on_play_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	weapon_slot.pressed.connect(_on_weapon_slot_pressed)
	defense_slot.pressed.connect(_on_defense_slot_pressed)
	utility_slot.pressed.connect(_on_utility_slot_pressed)
	chest_button.pressed.connect(_on_chest_pressed)


func update_ui() -> void:
	credits_label.text = "⭐ " + str(SaveManager.credits)
	high_score_label.text = "🏆 Лучший счёт: " + str(SaveManager.high_score)
	_refresh_slot_buttons()


func _refresh_slot_buttons() -> void:
	weapon_slot.text = "Оружие\n%s" % _slot_text("weapon")
	defense_slot.text = "Защита\n%s" % _slot_text("defense")
	utility_slot.text = "Утилита\n%s" % _slot_text("utility")

	# Подсветка доступности кнопки сундука
	var can_afford := SaveManager.credits >= CHEST_COST
	chest_button.disabled = not can_afford
	chest_button.modulate = Color(1, 1, 1, 1) if can_afford else Color(0.7, 0.7, 0.7, 0.8)


func _slot_text(slot: String) -> String:
	var module_id: String = SaveManager.get_equipped_in_slot(slot)
	if module_id.is_empty():
		return "[пусто]"
	return _module_display_name(module_id)


func _module_display_name(module_id: String) -> String:
	# Возвращает имя модуля, а если ресурс не найден — id
	if not MODULE_PATHS.has(module_id):
		return module_id
	var path: String = MODULE_PATHS[module_id]
	if not ResourceLoader.exists(path):
		return module_id
	var res: Resource = load(path)
	if res == null:
		return module_id
	if "name" in res:
		return str(res.name)
	return module_id


# ---------- Обработчики кнопок ----------

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/Main.tscn")


func _on_shop_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/screens/Shop.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_weapon_slot_pressed() -> void:
	_open_module_select("weapon")


func _on_defense_slot_pressed() -> void:
	_open_module_select("defense")


func _on_utility_slot_pressed() -> void:
	_open_module_select("utility")


func _on_chest_pressed() -> void:
	if not SaveManager.spend_credits(CHEST_COST):
		# Недостаточно кредитов
		_show_info("Недостаточно кредитов", "Нужно %d ⭐ для открытия сундука." % CHEST_COST)
		return

	# Случайный выбор модуля
	var rolled_module: String = CHEST_POOL[randi() % CHEST_POOL.size()]
	var is_new := SaveManager.add_module(rolled_module)

	if is_new:
		# Новый модуль — пробуем авто-экипировать в соответствующий слот, если он пуст
		var module_resource: Resource = load(MODULE_PATHS[rolled_module])
		var module_type: String = ""
		if module_resource != null and "type" in module_resource:
			module_type = str(module_resource.type)
		if not module_type.is_empty() and SaveManager.get_equipped_in_slot(module_type).is_empty():
			SaveManager.equip_module(module_type, rolled_module)
		_show_chest_result(rolled_module, true, 0)
	else:
		# Дубликат — компенсация
		SaveManager.add_credits(CHEST_DUPLICATE_COMPENSATION)
		_show_chest_result(rolled_module, false, CHEST_DUPLICATE_COMPENSATION)

	update_ui()


# ---------- Popups ----------

func _open_module_select(slot: String) -> void:
	var popup: CanvasLayer = MODULE_SELECT_SCENE.instantiate()
	add_child(popup)
	if popup.has_method("setup"):
		popup.setup(slot)
	if popup.has_signal("module_selected"):
		popup.module_selected.connect(_on_module_selected.bind(slot))
	if popup.has_signal("popup_closed"):
		popup.popup_closed.connect(_on_popup_closed)


func _on_module_selected(module_id: String, slot: String) -> void:
	SaveManager.equip_module(slot, module_id)
	update_ui()


func _on_popup_closed() -> void:
	update_ui()


func _show_chest_result(module_id: String, is_new: bool, compensation: int) -> void:
	var popup: CanvasLayer = CHEST_OPEN_SCENE.instantiate()
	add_child(popup)
	if popup.has_method("setup"):
		popup.setup(module_id, is_new, compensation)
	if popup.has_signal("popup_closed"):
		popup.popup_closed.connect(_on_popup_closed)


func _show_info(title: String, message: String) -> void:
	# Простой info popup — переиспользуем ChestOpen, подменив содержимое
	var popup: CanvasLayer = CHEST_OPEN_SCENE.instantiate()
	add_child(popup)
	# Настроим напрямую
	if popup.has_method("setup"):
		# Передаём id-заглушку и помечаем как new=true, чтобы UI остался читаемым
		# (для info-сообщений лучше в будущем сделать отдельный info popup)
		popup.setup("info", true, 0)
		# Перепишем текст вручную
		var title_node: Label = popup.find_child("TitleLabel", true, false) as Label
		var result_node: Label = popup.find_child("ResultLabel", true, false) as Label
		if title_node:
			title_node.text = title
		if result_node:
			result_node.text = message
	if popup.has_signal("popup_closed"):
		popup.popup_closed.connect(_on_popup_closed)
