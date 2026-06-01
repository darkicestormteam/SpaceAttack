extends CanvasLayer

signal module_selected(module_id: String)
signal popup_closed

const MODULE_PATHS: Dictionary = {
	"laser": "res://data/modules/Laser_Common.tres",
	"shotgun": "res://data/modules/shotgun.tres",
	"rocket": "res://data/modules/rocket.tres",
	"shield": "res://data/modules/shield.tres",
	"energy_shield": "res://data/modules/energy_shield.tres",
	"reactive_armor": "res://data/modules/reactive_armor.tres",
	"magnet": "res://data/modules/magnet.tres",
	"shockwave": "res://data/modules/shockwave.tres",
	"turbo": "res://data/modules/turbo.tres",
	"nanobots": "res://data/modules/nanobots.tres"
}

const WEAPON_MODULES: Array = ["laser", "shotgun", "rocket"]
const DEFENSE_MODULES: Array = ["shield", "energy_shield", "reactive_armor"]
const UTILITY_MODULES: Array = ["magnet", "shockwave", "turbo", "nanobots"]

var _target_slot: String = "weapon"

@onready var title_label: Label = %TitleLabel
@onready var list_container: VBoxContainer = %ListContainer
@onready var close_button: Button = %CloseButton
@onready var unequip_button: Button = %UnequipButton


func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	unequip_button.pressed.connect(_on_unequip_pressed)


func setup(slot: String) -> void:
	_target_slot = slot
	title_label.text = "Выберите модуль: %s" % _slot_display_name(slot)
	_refresh_list()


func _refresh_list() -> void:
	for child in list_container.get_children():
		child.queue_free()

	var owned_ids: Array = SaveManager.get_owned_module_ids()
	var has_any_for_slot := false

	for module_id in owned_ids:
		var mid := str(module_id)
		var module_type: String = ""
		if mid in WEAPON_MODULES:
			module_type = "weapon"
		elif mid in DEFENSE_MODULES:
			module_type = "defense"
		elif mid in UTILITY_MODULES:
			module_type = "utility"
		if module_type != _target_slot:
			continue

		has_any_for_slot = true
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 64)

		var module_resource: Resource = _load_module(module_id)
		var display_name: String = module_id
		if module_resource != null:
			display_name = _get_module_name(module_resource, module_id)
		var name_label := Label.new()
		name_label.text = display_name
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(name_label)

		var equip_btn := Button.new()
		equip_btn.text = "Надеть"
		equip_btn.custom_minimum_size = Vector2(120, 48)
		equip_btn.pressed.connect(_on_module_chosen.bind(module_id))
		row.add_child(equip_btn)

		list_container.add_child(row)

	if not has_any_for_slot:
		var empty_label := Label.new()
		empty_label.text = "Нет доступных модулей для этого слота.\nОткройте сундук!"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list_container.add_child(empty_label)


func _load_module(module_id: String) -> Resource:
	if not MODULE_PATHS.has(module_id):
		return null
	var path: String = MODULE_PATHS[module_id]
	if not ResourceLoader.exists(path):
		return null
	return load(path)


func _get_module_type(module_resource: Resource) -> String:
	if module_resource == null:
		return ""
	if "type" in module_resource:
		return str(module_resource.type)
	return ""


func _get_module_name(module_resource: Resource, fallback: String) -> String:
	if module_resource == null:
		return fallback
	if "name" in module_resource:
		return str(module_resource.name)
	return fallback


func _on_module_chosen(module_id: String) -> void:
	module_selected.emit(module_id)
	queue_free()


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
		_:
			return slot