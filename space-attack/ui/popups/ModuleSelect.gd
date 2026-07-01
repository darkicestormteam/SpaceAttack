extends CanvasLayer

signal module_selected(module_id: String)
signal popup_closed

const MODULE_DETAIL_SCENE: PackedScene = preload("res://ui/popups/ModuleDetail.tscn")

const RARITY_COLORS: Dictionary = {
	"common": Color(1, 1, 1, 1),
	"rare": Color(0.3, 0.6, 1, 1),
	"epic": Color(0.7, 0.3, 1, 1),
	"legendary": Color(1, 0.7, 0.1, 1)
}

const MODULE_PATHS: Dictionary = {
	"laser": "res://data/modules/Laser_Common.tres",
	"laser_mk2": "res://data/modules/Laser_MkII.tres",
	"laser_pierce": "res://data/modules/Laser_Pierce.tres",
	"laser_plasma": "res://data/modules/Laser_Plasma.tres",
	"shotgun": "res://data/modules/shotgun.tres",
	"shotgun_whistle": "res://data/modules/shotgun_whistle.tres",
	"shotgun_pressure": "res://data/modules/shotgun_pressure.tres",
	"shotgun_heavy": "res://data/modules/shotgun_heavy.tres",
	"rocket": "res://data/modules/rocket.tres",
	"rocket_mk2": "res://data/modules/rocket_mk2.tres",
	"rocket_homing": "res://data/modules/rocket_homing.tres",
	"rocket_nuke": "res://data/modules/rocket_nuke.tres",
	"light_armor": "res://data/modules/light_armor.tres",
	"shield": "res://data/modules/shield_new.tres",
	"composite_armor": "res://data/modules/composite_armor.tres",
	"forsage": "res://data/modules/forsage.tres",
	"tactical_accelerator": "res://data/modules/tactical_accelerator.tres",
	"diffusor": "res://data/modules/diffusor.tres",
	"cocoon_shield": "res://data/modules/cocoon_shield.tres",
	"drone": "res://data/modules/drone.tres",
	"drone_rare": "res://data/modules/drone_rare.tres",
	"drone_epic": "res://data/modules/drone_epic.tres",
	"drone_legendary": "res://data/modules/drone_legendary.tres",
	"shockwave": "res://data/modules/shockwave.tres",
	"turbo": "res://data/modules/turbo.tres",
	"nanobots": "res://data/modules/nanobots.tres",
	"skin_vanguard_0": "res://data/modules/skin_vanguard_0.tres",
	"skin_vanguard_1": "res://data/modules/skin_vanguard_1.tres",
	"skin_vanguard_2": "res://data/modules/skin_vanguard_2.tres",
	"skin_phantom_0": "res://data/modules/skin_phantom_0.tres",
	"skin_phantom_1": "res://data/modules/skin_phantom_1.tres",
	"skin_phantom_2": "res://data/modules/skin_phantom_2.tres",
	"skin_goliath_0": "res://data/modules/skin_goliath_0.tres",
	"skin_goliath_1": "res://data/modules/skin_goliath_1.tres",
	"skin_goliath_2": "res://data/modules/skin_goliath_2.tres",
}

const MODULE_BUTTON_SCENE: PackedScene = preload("res://ui/popups/ModuleButton.tscn")

const DEFAULT_VISUALS_PATH: String = "res://data/visuals/default_module_visuals.tres"

var _target_slot: String = "weapon"
var _module_cache: Dictionary = {}

@onready var title_label: Label = %TitleLabel
@onready var list_container: VBoxContainer = %ListContainer
@onready var close_button: Button = %CloseButton
@onready var unequip_button: Button = %UnequipButton


func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	unequip_button.pressed.connect(_on_unequip_pressed)
	_setup_localization()
	if LocalizationManager.language_changed.is_connected(_on_language_changed):
		LocalizationManager.language_changed.disconnect(_on_language_changed)
	LocalizationManager.language_changed.connect(_on_language_changed)


func _setup_localization() -> void:
	title_label.text = tr("select_title") % tr("select_slot_" + _target_slot)
	unequip_button.text = tr("select_unequip")
	close_button.text = tr("select_close")


func _on_language_changed(_locale: String) -> void:
	_setup_localization()


func setup(slot: String) -> void:
	_target_slot = slot
	title_label.text = tr("select_title") % tr("select_slot_" + slot)
	_refresh_list()


func _refresh_list() -> void:
	for child in list_container.get_children():
		child.queue_free()

	var owned_ids: Array = SaveManager.get_owned_module_ids()
	var has_any_for_slot := false

	for raw_id in owned_ids:
		var mid := str(raw_id)
		if not _module_matches_slot(mid, _target_slot):
			continue

		# Для скинов — показываем только реально разблокированные, не все подряд
		if mid.begins_with("skin_"):
			var parts := mid.split("_")
			if parts.size() < 3:
				continue
			var ship_id := parts[1]
			var skin_idx := int(parts[2])
			if not SaveManager.is_skin_unlocked(ship_id, skin_idx):
				continue

		has_any_for_slot = true
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 128)

		# Иконка (слева)
		var btn: ModuleButton = MODULE_BUTTON_SCENE.instantiate()
		row.add_child(btn)
		btn.setup(mid, _load_visuals_for(mid))
		btn.pressed_with_id.connect(_on_module_chosen)

		# Название (справа от иконки)
		var name_label := Label.new()
		name_label.text = _get_module_name_safe(mid)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 28)
		var module_res: Resource = _load_module(mid)
		if module_res != null and "rarity" in module_res:
			name_label.add_theme_color_override("font_color", RARITY_COLORS.get(str(module_res.rarity), Color.WHITE))
		row.add_child(name_label)
		list_container.add_child(row)

	if not has_any_for_slot:
		var empty_label := Label.new()
		empty_label.text = tr("select_empty")
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list_container.add_child(empty_label)


func _module_matches_slot(mid: String, slot: String) -> bool:
	if slot == "skin":
		return mid.begins_with("skin_")
	var module_res: Resource = _load_module(mid)
	if module_res == null:
		return false
	if "type" not in module_res:
		return false
	return str(module_res.type) == slot


func _load_visuals_for(module_id: String) -> Resource:
	var per_id: String = "res://data/visuals/%s_visuals.tres" % module_id
	if ResourceLoader.exists(per_id):
		var res: Resource = load(per_id)
		if res != null:
			return res
	if ResourceLoader.exists(DEFAULT_VISUALS_PATH):
		return load(DEFAULT_VISUALS_PATH)
	return null


func _get_module_name_safe(module_id: String) -> String:
	return tr("mod_" + module_id + "_name")


func _load_module(module_id: String) -> Resource:
	if _module_cache.has(module_id):
		return _module_cache[module_id]
	if not MODULE_PATHS.has(module_id):
		return null
	var path: String = MODULE_PATHS[module_id]
	if not ResourceLoader.exists(path):
		return null
	var res: Resource = load(path)
	if res != null:
		_module_cache[module_id] = res
	return res


func _on_module_chosen(module_id: String) -> void:
	_open_module_detail(module_id)


func _open_module_detail(module_id: String) -> void:
	var detail: CanvasLayer = MODULE_DETAIL_SCENE.instantiate()
	add_child(detail)
	detail.setup(module_id, _target_slot)
	detail.module_confirmed.connect(_on_detail_confirmed)
	detail.detail_closed.connect(_on_detail_closed)
	# Скрываем список модулей — окно деталей поверх
	visible = false


func _on_detail_confirmed(module_id: String) -> void:
	module_selected.emit(module_id)
	queue_free()


func _on_detail_closed() -> void:
	# Показываем список модулей обратно
	visible = true


func _on_close_pressed() -> void:
	popup_closed.emit()
	queue_free()


func _on_unequip_pressed() -> void:
	SaveManager.unequip_module(_target_slot)
	popup_closed.emit()
	queue_free()


func _slot_display_name(slot: String) -> String:
	match slot:
		"weapon":
			return "Оружие"
		"defense":
			return "Защита"
		"utility":
			return "Утилита"
		"skin":
			return "Скины"
		_:
			return slot
