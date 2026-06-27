extends CanvasLayer

## Экран победы после 10 волны.
##
## При нажатии "В ангар" или "Рестарт" сначала показывает
## DoubleCreditsPopup — предложение удвоить кредиты за рекламу.

signal hangar_requested

const DOUBLE_CREDITS_POPUP: PackedScene = preload("res://ui/popups/DoubleCreditsPopup.tscn")

# UI элементы
var dim: ColorRect
var panel: VBoxContainer

var score: int = 0
var credits: int = 0
var credits_earned: int = 0
var _is_action_pending: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()


func set_stats(final_score: int, final_credits: int, earned: int = 0) -> void:
	score = final_score
	credits = final_credits
	credits_earned = earned
	if panel:
		_refresh_labels()


func _refresh_labels() -> void:
	for child in panel.get_children():
		if child is Label and child.name == "ScoreLabel":
			child.text = "Очки: %d" % score
		if child is Label and child.name == "CreditsLabel":
			child.text = "Кредиты: %d" % credits


func _build_ui() -> void:
	# Затемнение фона
	dim = ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0, 0, 0, 0.8)
	dim.anchors_preset = Control.PRESET_FULL_RECT
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	# Панель
	panel = VBoxContainer.new()
	panel.name = "VictoryPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -200
	panel.offset_top = -240
	panel.offset_right = 200
	panel.offset_bottom = 240
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.add_theme_constant_override("separation", 16)
	panel.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(panel)

	# Заголовок
	var title := Label.new()
	title.text = "Поздравляю! Вы победили!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1, 0.8, 0.2, 1))
	panel.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	panel.add_child(spacer)

	# Очки
	var score_label := Label.new()
	score_label.name = "ScoreLabel"
	score_label.text = "Очки: %d" % score
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 22)
	score_label.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(score_label)

	# Кредиты
	var credits_label := Label.new()
	credits_label.name = "CreditsLabel"
	credits_label.text = "Кредиты: %d" % credits
	credits_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credits_label.add_theme_font_size_override("font_size", 22)
	credits_label.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(credits_label)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	panel.add_child(spacer2)

	# Кнопка "В ангар"
	var hangar_btn := Button.new()
	hangar_btn.text = "В ангар"
	hangar_btn.custom_minimum_size = Vector2(280, 70)
	hangar_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hangar_btn.add_theme_font_size_override("font_size", 24)
	hangar_btn.pressed.connect(_on_hangar_pressed)
	panel.add_child(hangar_btn)

	# Кнопка "Рестарт"
	var restart_btn := Button.new()
	restart_btn.text = "Рестарт"
	restart_btn.custom_minimum_size = Vector2(280, 70)
	restart_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	restart_btn.add_theme_font_size_override("font_size", 24)
	restart_btn.pressed.connect(_on_restart_pressed)
	panel.add_child(restart_btn)

	# Применяем стиль
	_apply_styles_to_buttons()


func _apply_styles_to_buttons() -> void:
	for child in panel.get_children():
		if child is Button:
			_apply_button_style(child)


func _apply_button_style(btn: Button) -> void:
	if btn == null:
		return
	
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.0, 0.0, 0.0, 0.7)
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(0.3, 0.6, 1, 1)
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.1, 0.1, 0.2, 0.8)
	hover.border_width_left = 2
	hover.border_width_top = 2
	hover.border_width_right = 2
	hover.border_width_bottom = 2
	hover.border_color = Color(0.5, 0.8, 1, 1)
	hover.corner_radius_top_left = 8
	hover.corner_radius_top_right = 8
	hover.corner_radius_bottom_left = 8
	hover.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("hover", hover)

	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 24)


# ============================================================
# "В ангар" — с попапом удвоения
# ============================================================

func _on_hangar_pressed() -> void:
	if _is_action_pending:
		return
	_is_action_pending = true
	
	var should_double := false
	if credits_earned > 0:
		should_double = await _show_double_credits_popup()
	
	get_tree().paused = false
	await _request_review_and_go_hangar(should_double)


# ============================================================
# "Рестарт" — с попапом удвоения
# ============================================================

func _on_restart_pressed() -> void:
	if _is_action_pending:
		return
	_is_action_pending = true
	
	if credits_earned > 0:
		await _show_double_credits_popup()
	
	get_tree().paused = false
	get_tree().reload_current_scene()


# ============================================================
# Показ попапа удвоения кредитов
# ============================================================

## Возвращает true, если игрок сказал "да" (хочет удвоить).
func _show_double_credits_popup() -> bool:
	# Прячем UI на время попапа
	if dim:
		dim.visible = false
	if panel:
		panel.visible = false
	
	var popup = DOUBLE_CREDITS_POPUP.instantiate()
	add_child(popup)
	popup.setup(credits_earned)
	
	var choice := "no"
	if popup.has_signal("choice_made"):
		choice = await popup.choice_made
	else:
		await popup.action_completed
		choice = "yes"
	
	if is_instance_valid(popup):
		popup.queue_free()
	
	# Возвращаем UI
	if dim:
		dim.visible = true
	if panel:
		panel.visible = true
	
	return choice == "yes"


# ============================================================
# Feedback + Queue + Hangar
# ============================================================

func _request_review_and_go_hangar(should_double: bool = false) -> void:
	var ads = get_node_or_null("/root/AdsManager") as Node
	if ads == null or not ads.has_method("request_review_if_possible"):
		get_tree().change_scene_to_file("res://ui/screens/Hangar.tscn")
		return
	
	# Запрос отзыва (до рекламы)
	if ads.is_sdk_ready:
		await ads.request_review_if_possible()
	
	# Добавляем rewarded для удвоения
	if should_double and credits_earned > 0:
		ads.queue_rewarded_double(credits_earned)
	
	# Добавляем interstitial
	ads.queue_interstitial()
	
	# Ждём завершения очереди
	await ads.queue_completed
	
	get_tree().change_scene_to_file("res://ui/screens/Hangar.tscn")