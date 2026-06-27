extends Control

signal animation_finished

@onready var icon_rect: TextureRect = $Panel/MarginContainer/HBoxContainer/IconRect
@onready var name_label: Label = $Panel/MarginContainer/HBoxContainer/VBox/NameLabel
@onready var reward_label: Label = $Panel/MarginContainer/HBoxContainer/VBox/RewardLabel
@onready var panel: Panel = $Panel

var _elapsed: float = 0.0
var _phase: int = 0  # 0=show, 1=wait, 2=hide, 3=done

const SHOW_DURATION: float = 0.35
const WAIT_DURATION: float = 3.0
const HIDE_DURATION: float = 0.5

const RARITY_COLORS: Dictionary = {
	"bronze": Color(0.8, 0.5, 0.2),
	"silver": Color(0.6, 0.75, 0.9),
	"gold": Color(1.0, 0.75, 0.1),
	"legendary": Color(1.0, 0.3, 0.1)
}


func setup(ach_id: String, ach_data: Dictionary) -> void:
	var rarity: String = ach_data.get("rarity", "bronze")
	var reward: int = ach_data.get("reward", 0)
	var name_text: String = ach_data.get("name", ach_id)
	
	name_label.text = name_text
	name_label.add_theme_font_size_override("font_size", 24)
	
	reward_label.text = "+%d " % reward
	reward_label.add_theme_font_size_override("font_size", 18)
	
	var rarity_color: Color = RARITY_COLORS.get(rarity, Color.WHITE)
	panel.add_theme_stylebox_override("panel", _make_panel_style(rarity_color))
	
	_build_icon(ach_id, rarity)
	
	# Начальное состояние
	modulate = Color(1, 1, 1, 0)
	scale = Vector2(0.5, 0.5)
	_elapsed = 0.0
	_phase = 0
	
	# Позиционируем в центре экрана (сразу, без await)
	_center_on_screen()
	
	set_process(true)


func _center_on_screen() -> void:
	if get_viewport() == null:
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	custom_minimum_size = Vector2(320, 80)
	position = Vector2(viewport_size.x * 0.5 - 160, viewport_size.y * 0.1)


func _process(delta: float) -> void:
	_elapsed += delta
	
	match _phase:
		0:  # Show animation
			var t: float = minf(_elapsed / SHOW_DURATION, 1.0)
			t = ease_out_back(t)
			scale = Vector2(0.5 + 0.5 * t, 0.5 + 0.5 * t)
			modulate = Color(1, 1, 1, t)
			if _elapsed >= SHOW_DURATION:
				_elapsed = 0.0
				_phase = 1
		
		1:  # Wait
			if _elapsed >= WAIT_DURATION:
				_elapsed = 0.0
				_phase = 2
		
		2:  # Hide animation
			var t: float = minf(_elapsed / HIDE_DURATION, 1.0)
			modulate = Color(1, 1, 1, 1.0 - t)
			scale = Vector2(1.0 - 0.2 * t, 1.0 - 0.2 * t)
			if _elapsed >= HIDE_DURATION:
				_phase = 3
				set_process(false)
				animation_finished.emit()
				queue_free()


static func ease_out_back(x: float) -> float:
	var c1: float = 1.70158
	var c3: float = c1 + 1.0
	return 1.0 + c3 * pow(x - 1.0, 3) + c1 * pow(x - 1.0, 2)


func _build_icon(ach_id: String, rarity: String) -> void:
	var icon_path := "res://assets/icons/achievements/" + ach_id + ".png"
	if ResourceLoader.exists(icon_path):
		icon_rect.texture = load(icon_path)
		icon_rect.modulate = Color.WHITE
		return
	
	icon_rect.texture = null
	for child in icon_rect.get_children():
		child.queue_free()
	
	icon_rect.modulate = Color.WHITE
	
	var initial_letter := name_label.text.left(1).to_upper()
	var letter_label := Label.new()
	letter_label.text = initial_letter
	letter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	letter_label.add_theme_font_size_override("font_size", 32)
	letter_label.modulate = RARITY_COLORS.get(rarity, Color.WHITE)
	letter_label.custom_minimum_size = Vector2(64, 64)
	icon_rect.add_child(letter_label)


func _make_panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.92)
	style.border_color = color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style
