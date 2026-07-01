extends HBoxContainer

var icon_placeholder: TextureRect
var name_label: Label
var desc_label: Label
var category_label: Label

# Константы из AchievementsList (копируем для работы)
const RARITY_COLORS: Dictionary = {
	"bronze": Color(0.8, 0.5, 0.2, 1),
	"silver": Color(0.6, 0.75, 0.9, 1),
	"gold": Color(1, 0.75, 0.1, 1),
	"legendary": Color(1, 0.3, 0.1, 1)
}

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


func _ready() -> void:
	# Убеждаемся, что custom_minimum_size установлен
	custom_minimum_size = Vector2(0, 140)


# Заполняет строку данными ачивки
# Ищем ноды прямо здесь, т.к. _ready() может быть ещё не вызван
func setup(ach_id: String, ach_data: Dictionary, unlocked: bool) -> void:
	# Ищем ноды (гарантированно работаем даже без _ready)
	icon_placeholder = find_child("IconContainer", true, false) as TextureRect
	name_label = find_child("NameLabel", true, false) as Label
	desc_label = find_child("DescLabel", true, false) as Label
	category_label = find_child("CategoryLabel", true, false) as Label
	
	if icon_placeholder == null or name_label == null or desc_label == null or category_label == null:
		push_error("AchievementRow: не удалось найти ноды после instantiate!")
		return
	
	var name_text: String = ach_data.get("name", "")
	var rarity: String = ach_data.get("rarity", "bronze")
	
	# --- Иконка (PNG из папки, если есть, иначе заглушка) ---
	_build_icon(ach_id, name_text, rarity, unlocked)
	
	# --- Название ---
	name_label.text = name_text
	name_label.add_theme_font_size_override("font_size", 24)
	if unlocked:
		name_label.modulate = RARITY_COLORS.get(rarity, Color.WHITE)
	else:
		name_label.modulate = Color(0.4, 0.4, 0.4, 1)
	
	# --- Описание ---
	desc_label.text = ach_data.get("description", "")
	desc_label.add_theme_font_size_override("font_size", 22)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	if unlocked:
		desc_label.modulate = Color(0.8, 0.8, 0.8, 1)
	else:
		desc_label.modulate = Color(0.3, 0.3, 0.3, 1)
	
	# --- Категория ---
	var cat: String = ach_data.get("category", "")
	category_label.text = CATEGORY_ICONS.get(cat, "") + " " + tr(CATEGORY_NAMES.get(cat, ""))
	category_label.add_theme_font_size_override("font_size", 18)
	category_label.modulate = Color(0.5, 0.5, 0.5, 0.7)


# Пытается загрузить PNG иконку. Если нет PNG — рисует заглушку (буква + цвет)
func _build_icon(ach_id: String, name_text: String, rarity: String, unlocked: bool) -> void:
	# Очищаем контейнер
	for child in icon_placeholder.get_children():
		child.queue_free()
	icon_placeholder.texture = null
	
	# Настройки для корректного отображения иконок
	icon_placeholder.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	icon_placeholder.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Пробуем загрузить PNG из папки assets/icons/achievements/
	var icon_path := "res://assets/icons/achievements/" + ach_id + ".png"
	if ResourceLoader.exists(icon_path):
		icon_placeholder.texture = load(icon_path)
		if unlocked:
			icon_placeholder.modulate = Color.WHITE
		else:
			icon_placeholder.modulate = Color(0.3, 0.3, 0.35, 0.6)
		return
	
	# Если PNG нет — заглушка: цвет редкости + первая буква
	var bg := ColorRect.new()
	bg.size = Vector2(128, 128)
	bg.custom_minimum_size = Vector2(128, 128)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if unlocked:
		bg.color = RARITY_COLORS.get(rarity, Color.WHITE) * Color(1, 1, 1, 0.2)
	else:
		bg.color = Color(0.12, 0.12, 0.14, 1)
	icon_placeholder.modulate = Color.WHITE
	icon_placeholder.add_child(bg)
	
	var letter := Label.new()
	letter.text = name_text.left(1).to_upper()
	letter.size = Vector2(128, 128)
	letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	letter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	letter.add_theme_font_size_override("font_size", 48)
	
	if unlocked:
		letter.modulate = RARITY_COLORS.get(rarity, Color.WHITE)
	else:
		letter.modulate = Color(0.3, 0.3, 0.35, 0.8)
	icon_placeholder.add_child(letter)
