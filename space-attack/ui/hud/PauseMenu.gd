extends CanvasLayer

signal resumed
signal restart_requested
signal hangar_requested

var pending_action: String = ""  # "hangar" или "restart"

# UI элементы (создаются в _ready)
var menu_button: Button
var dim: ColorRect
var panel: VBoxContainer
var confirm_panel: VBoxContainer
var confirm_label: Label
var confirm_yes: Button
var confirm_no: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	hide_menu()


func _build_ui() -> void:
	# --- Кнопка меню (☰) в правом верхнем углу ---
	menu_button = Button.new()
	menu_button.name = "MenuButton"
	menu_button.text = "☰"
	menu_button.custom_minimum_size = Vector2(64, 64)
	menu_button.size = Vector2(64, 64)
	menu_button.position = Vector2(720 - 64 - 16, 16)
	menu_button.pressed.connect(_on_menu_button_pressed)
	add_child(menu_button)

	# --- Затемнение фона ---
	dim = ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.visible = false
	add_child(dim)

	# --- Панель меню (центр) ---
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
	resume_btn.custom_minimum_size = Vector2(200, 70)
	resume_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	resume_btn.add_theme_font_size_override("font_size", 24)
	resume_btn.pressed.connect(_on_resume_pressed)
	panel.add_child(resume_btn)

	var hangar_btn := Button.new()
	hangar_btn.text = "В ангар"
	hangar_btn.custom_minimum_size = Vector2(200, 70)
	hangar_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hangar_btn.add_theme_font_size_override("font_size", 24)
	hangar_btn.pressed.connect(_on_hangar_pressed)
	panel.add_child(hangar_btn)

	var restart_btn := Button.new()
	restart_btn.text = "Рестарт"
	restart_btn.custom_minimum_size = Vector2(200, 70)
	restart_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	restart_btn.add_theme_font_size_override("font_size", 24)
	restart_btn.pressed.connect(_on_restart_pressed)
	panel.add_child(restart_btn)

	# --- Диалог подтверждения (поверх панели меню) ---
	confirm_panel = VBoxContainer.new()
	confirm_panel.name = "ConfirmPanel"
	confirm_panel.set_anchors_preset(Control.PRESET_CENTER)
	confirm_panel.offset_left = -250
	confirm_panel.offset_top = -120
	confirm_panel.offset_right = 250
	confirm_panel.offset_bottom = 120
	confirm_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	confirm_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	confirm_panel.add_theme_constant_override("separation", 20)
	confirm_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	confirm_panel.visible = false
	add_child(confirm_panel)

	confirm_label = Label.new()
	confirm_label.text = "Весь прогресс текущего забега\nбудет потерян.\nПродолжить?"
	confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_label.add_theme_font_size_override("font_size", 22)
	confirm_label.add_theme_color_override("font_color", Color.WHITE)
	confirm_panel.add_child(confirm_label)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 30)
	confirm_panel.add_child(btn_row)

	confirm_yes = Button.new()
	confirm_yes.text = "Да"
	confirm_yes.custom_minimum_size = Vector2(120, 64)
	confirm_yes.add_theme_font_size_override("font_size", 24)
	confirm_yes.pressed.connect(_on_confirm_yes)
	btn_row.add_child(confirm_yes)

	confirm_no = Button.new()
	confirm_no.text = "Нет"
	confirm_no.custom_minimum_size = Vector2(120, 64)
	confirm_no.add_theme_font_size_override("font_size", 24)
	confirm_no.pressed.connect(_on_confirm_no)
	btn_row.add_child(confirm_no)


func show_menu() -> void:
	dim.visible = true
	panel.visible = true
	menu_button.visible = false
	get_tree().paused = true
	# Анимация появления
	panel.modulate = Color(1, 1, 1, 0)
	panel.scale = Vector2(0.8, 0.8)
	panel.pivot_offset = panel.size / 2
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "modulate", Color.WHITE, 0.2)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func hide_menu() -> void:
	dim.visible = false
	panel.visible = false
	confirm_panel.visible = false
	menu_button.visible = true


func _on_menu_button_pressed() -> void:
	show_menu()


func _on_resume_pressed() -> void:
	get_tree().paused = false
	hide_menu()
	resumed.emit()


func _on_hangar_pressed() -> void:
	pending_action = "hangar"
	_show_confirm()


func _on_restart_pressed() -> void:
	pending_action = "restart"
	_show_confirm()


func _show_confirm() -> void:
	panel.visible = false
	confirm_panel.visible = true


func _hide_confirm() -> void:
	confirm_panel.visible = false
	panel.visible = true
	pending_action = ""


func _on_confirm_yes() -> void:
	var action := pending_action
	_hide_confirm()
	get_tree().paused = false
	hide_menu()
	if action == "hangar":
		hangar_requested.emit()
	elif action == "restart":
		restart_requested.emit()


func _on_confirm_no() -> void:
	_hide_confirm()
