extends CanvasLayer

signal popup_closed

const RARITY_COLORS: Dictionary = {
	"bronze": Color(0.8, 0.5, 0.2, 1),
	"silver": Color(0.6, 0.75, 0.9, 1),
	"gold": Color(1, 0.75, 0.1, 1),
	"legendary": Color(1, 0.3, 0.1, 1)
}

# Цвета фона иконок для locked/unlocked
const RARITY_BG_COLORS: Dictionary = {
	"bronze": Color(0.3, 0.18, 0.07, 0.6),
	"silver": Color(0.15, 0.22, 0.35, 0.6),
	"gold": Color(0.35, 0.26, 0.03, 0.6),
	"legendary": Color(0.4, 0.1, 0.03, 0.6)
}

const LOCKED_ICON_BG: Color = Color(0.12, 0.12, 0.14, 1)
const LOCKED_ICON_FG: Color = Color(0.3, 0.3, 0.35, 0.8)

const CATEGORY_NAMES: Dictionary = {
	"progress": "cat_progress",
	"ships": "cat_ships",
	"weapons": "cat_weapons",
	"mastery": "cat_mastery",
	"economy": "cat_economy",
	"special": "cat_special"
}

const CATEGORY_ICONS: Dictionary = {
	"progress": "",
	"ships": "",
	"weapons": "",
	"mastery": "",
	"economy": "",
	"special": ""
}

const ROW_SCENE: PackedScene = preload("res://ui/popups/AchievementRow.tscn")

var _sm: Node

@onready var dim: ColorRect = $Dim
@onready var title_label: Label = $Panel/VBox/TopBar/TitleLabel
@onready var stats_label: Label = $Panel/VBox/TopBar/StatsLabel
@onready var achievement_list: VBoxContainer = $Panel/VBox/ScrollContainer/AchievementList
@onready var close_button: Button = $Panel/VBox/TopBar/CloseButton


func _ready() -> void:
	_sm = get_node("/root/SaveManager")
	_setup_localization()
	if LocalizationManager.language_changed.is_connected(_on_language_changed):
		LocalizationManager.language_changed.disconnect(_on_language_changed)
	LocalizationManager.language_changed.connect(_on_language_changed)


func _setup_localization() -> void:
	for child in achievement_list.get_children():
		child.queue_free()
	
	var unlocked_count: int = _sm.get_achievement_count()
	var total: int = SaveManager.ACHIEVEMENTS_TOTAL
	stats_label.text = "%d / %d • %.0f%%" % [unlocked_count, total, float(unlocked_count) / float(max(total, 1)) * 100.0]
	title_label.text = tr("ach_title")
	
	var ach_ids: Array = _sm.get_all_achievement_ids()
	
	var unlocked_ids: Array[String] = []
	var locked_ids: Array[String] = []
	for ach_id in ach_ids:
		if _sm.is_achievement_unlocked(ach_id):
			unlocked_ids.append(ach_id)
		else:
			locked_ids.append(ach_id)
	
	for ach_id in unlocked_ids:
		var data: Dictionary = _sm.get_achievement_data(ach_id)
		_add_achievement_row(ach_id, data, true)
	
	var sep: HSeparator = HSeparator.new()
	sep.modulate = Color(0.5, 0.5, 0.5, 0.3)
	achievement_list.add_child(sep)
	
	var locked_label: Label = Label.new()
	locked_label.text = tr("ach_locked_header")
	locked_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	locked_label.modulate = Color(0.6, 0.6, 0.6, 0.6)
	locked_label.add_theme_font_size_override("font_size", 14)
	achievement_list.add_child(locked_label)
	
	for ach_id in locked_ids:
		var data: Dictionary = _sm.get_achievement_data(ach_id)
		_add_achievement_row(ach_id, data, false)
	
	# Подписываемся один раз
	if not close_button.pressed.is_connected(_on_close):
		close_button.pressed.connect(_on_close)


func _on_language_changed(_locale: String) -> void:
	_setup_localization()


func _add_achievement_row(ach_id: String, ach_data: Dictionary, unlocked: bool) -> void:
	# Загружаем готовую сцену строки ачивки
	var row: Node = ROW_SCENE.instantiate()
	row.setup(ach_id, ach_data, unlocked)
	achievement_list.add_child(row)
	
	# Разделитель между строками
	var sep2 := HSeparator.new()
	sep2.modulate = Color(0.5, 0.5, 0.5, 0.15)
	achievement_list.add_child(sep2)


func _on_close() -> void:
	popup_closed.emit()
	queue_free()
