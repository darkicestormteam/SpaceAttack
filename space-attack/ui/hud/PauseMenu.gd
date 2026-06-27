extends CanvasLayer

## Пауза.
##
## При нажатии "Рестарт" или "В ангар" показывает
## DoubleCreditsPopup (как в GameOver — через instantiate + add_child).

signal resumed
signal restart_requested
signal hangar_requested

const DOUBLE_CREDITS_POPUP: PackedScene = preload("res://ui/popups/DoubleCreditsPopup.tscn")

var _is_action_pending: bool = false

# UI элементы (создаются в _ready)
var menu_button: Button
var dim: ColorRect
var panel: VBoxContainer

# Подменю настроек
var settings_panel: VBoxContainer
var music_slider: HSlider
var sfx_slider: HSlider
var music_label: Label
var sfx_label: Label
var settings_back_btn: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	hide_menu()


func _build_ui() -> void:
	menu_button = Button.new()
	menu_button.name = "MenuButton"
	menu_button.text = "="
	menu_button.custom_minimum_size = Vector2(64, 64)
	menu_button.size = Vector2(64, 64)
	menu_button.position = Vector2(720 - 64 - 16, 16)
	menu_button.pressed.connect(_on_menu_button_pressed)
	add_child(menu_button)

	dim = ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.visible = false
	add_child(dim)

	panel = VBoxContainer.new()
	panel.name = "MenuPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -200
	panel.offset_top = -200
	panel.offset_right = 200
	panel.offset_bottom = 200
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.add_theme_constant_override("separation", 20)
	panel.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.visible = false
	add_child(panel)

	var title := Label.new()
	title.text = "ПАУЗА"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	panel.add_child(spacer)

	var resume_btn := Button.new()
	resume_btn.text = "Продолжить"
	resume_btn.custom_minimum_size = Vector2(400, 70)
	resume_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	resume_btn.add_theme_font_size_override("font_size", 24)
	resume_btn.pressed.connect(_on_resume_pressed)
	panel.add_child(resume_btn)

	var hangar_btn := Button.new()
	hangar_btn.text = "В ангар"
	hangar_btn.custom_minimum_size = Vector2(400, 70)
	hangar_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hangar_btn.add_theme_font_size_override("font_size", 24)
	hangar_btn.pressed.connect(_on_hangar_pressed)
	panel.add_child(hangar_btn)

	var restart_btn := Button.new()
	restart_btn.text = "Рестарт"
	restart_btn.custom_minimum_size = Vector2(400, 70)
	restart_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	restart_btn.add_theme_font_size_override("font_size", 24)
	restart_btn.pressed.connect(_on_restart_pressed)
	panel.add_child(restart_btn)

	var settings_btn := Button.new()
	settings_btn.text = "Настройки"
	settings_btn.custom_minimum_size = Vector2(400, 70)
	settings_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	settings_btn.add_theme_font_size_override("font_size", 24)
	settings_btn.pressed.connect(_show_settings)
	panel.add_child(settings_btn)

	# --- Подменю настроек ---
	settings_panel = VBoxContainer.new()
	settings_panel.name = "SettingsPanel"
	settings_panel.set_anchors_preset(Control.PRESET_CENTER)
	settings_panel.offset_left = -250
	settings_panel.offset_top = -250
	settings_panel.offset_right = 250
	settings_panel.offset_bottom = 250
	settings_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	settings_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	settings_panel.add_theme_constant_override("separation", 20)
	settings_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	settings_panel.visible = false
	add_child(settings_panel)

	var settings_title := Label.new()
	settings_title.text = "НАСТРОЙКИ"
	settings_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_title.add_theme_font_size_override("font_size", 36)
	settings_title.add_theme_color_override("font_color", Color.WHITE)
	settings_panel.add_child(settings_title)

	var music_row := HBoxContainer.new()
	music_row.alignment = BoxContainer.ALIGNMENT_CENTER
	music_row.add_theme_constant_override("separation", 15)
	music_row.custom_minimum_size = Vector2(400, 60)
	settings_panel.add_child(music_row)

	music_label = Label.new()
	music_label.text = "Музыка: 50%"
	music_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	music_label.add_theme_font_size_override("font_size", 22)
	music_label.add_theme_color_override("font_color", Color.WHITE)
	music_label.custom_minimum_size = Vector2(180, 0)
	music_row.add_child(music_label)

	music_slider = HSlider.new()
	music_slider.custom_minimum_size = Vector2(200, 50)
	music_slider.min_value = 0.0
	music_slider.max_value = 1.0
	music_slider.step = 0.01
	music_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	music_slider.value_changed.connect(_on_music_volume_changed)
	music_row.add_child(music_slider)

	var sfx_row := HBoxContainer.new()
	sfx_row.alignment = BoxContainer.ALIGNMENT_CENTER
	sfx_row.add_theme_constant_override("separation", 15)
	sfx_row.custom_minimum_size = Vector2(400, 60)
	settings_panel.add_child(sfx_row)

	sfx_label = Label.new()
	sfx_label.text = "Звуки: 50%"
	sfx_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	sfx_label.add_theme_font_size_override("font_size", 22)
	sfx_label.add_theme_color_override("font_color", Color.WHITE)
	sfx_label.custom_minimum_size = Vector2(180, 0)
	sfx_row.add_child(sfx_label)

	sfx_slider = HSlider.new()
	sfx_slider.custom_minimum_size = Vector2(200, 50)
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.01
	sfx_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	sfx_row.add_child(sfx_slider)

	var settings_spacer := Control.new()
	settings_spacer.custom_minimum_size = Vector2(0, 10)
	settings_panel.add_child(settings_spacer)

	settings_back_btn = Button.new()
	settings_back_btn.text = "Назад"
	settings_back_btn.custom_minimum_size = Vector2(200, 70)
	settings_back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	settings_back_btn.add_theme_font_size_override("font_size", 24)
	settings_back_btn.pressed.connect(_hide_settings)
	settings_panel.add_child(settings_back_btn)


func show_menu() -> void:
	dim.visible = true
	panel.visible = true
	menu_button.visible = false
	get_tree().paused = true


func hide_menu() -> void:
	dim.visible = false
	panel.visible = false
	settings_panel.visible = false
	menu_button.visible = true


func _sync_settings_sliders() -> void:
	var am := get_node_or_null("/root/AudioManager") as Node
	if am == null:
		return
	if music_slider:
		music_slider.value = am.music_volume
	if sfx_slider:
		sfx_slider.value = am.sfx_volume
	_update_volume_labels()
	
	
func _update_volume_labels() -> void:
	if music_label and music_slider:
		music_label.text = "Музыка: %d%%" % int(music_slider.value * 100.0)
	if sfx_label and sfx_slider:
		sfx_label.text = "Звуки: %d%%" % int(sfx_slider.value * 100.0)


func _show_settings() -> void:
	_sync_settings_sliders()
	panel.visible = false
	settings_panel.visible = true


func _hide_settings() -> void:
	settings_panel.visible = false
	panel.visible = true


func _on_music_volume_changed(value: float) -> void:
	var am := get_node_or_null("/root/AudioManager") as Node
	if am and am.has_method(&"set_music_volume"):
		am.set_music_volume(value)
	_update_volume_labels()


func _on_sfx_volume_changed(value: float) -> void:
	var am := get_node_or_null("/root/AudioManager") as Node
	if am and am.has_method(&"set_sfx_volume"):
		am.set_sfx_volume(value)
	_update_volume_labels()


func _on_menu_button_pressed() -> void:
	show_menu()


func _on_resume_pressed() -> void:
	get_tree().paused = false
	hide_menu()
	resumed.emit()


# ============================================================
# "В ангар" — динамический попап (как в GameOver.gd)
# ============================================================

func _on_hangar_pressed() -> void:
	if _is_action_pending:
		return
	_is_action_pending = true
	
	await _show_double_credits_popup_if_earned()
	
	get_tree().paused = false
	hide_menu()
	hangar_requested.emit()
	_is_action_pending = false


# ============================================================
# "Рестарт" — динамический попап (как в GameOver.gd)
# ============================================================

func _on_restart_pressed() -> void:
	if _is_action_pending:
		return
	_is_action_pending = true
	
	await _show_double_credits_popup_if_earned()
	
	get_tree().paused = false
	hide_menu()
	restart_requested.emit()
	_is_action_pending = false


# ============================================================
# Показ попапа — ТОЧНО КАК В GameOver.gd
# ============================================================

func _show_double_credits_popup_if_earned() -> void:
	var main = get_tree().current_scene
	var credits_earned: int = 0
	if main:
		credits_earned = int(main.get("credits_earned_this_run"))
	
	if credits_earned <= 0:
		return
	
	# Прячем панель меню на время попапа (чтобы не перекрывали клики)
	dim.visible = false
	panel.visible = false
	
	# Создаём попап динамически — ТОЧНО КАК В GameOver
	var popup = DOUBLE_CREDITS_POPUP.instantiate()
	add_child(popup)
	popup.setup(credits_earned)
	await popup.action_completed
	
	# Удаляем попап
	if is_instance_valid(popup):
		popup.queue_free()
	
	# Возвращаем панель меню
	dim.visible = true
	panel.visible = true
