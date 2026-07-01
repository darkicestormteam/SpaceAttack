extends CanvasLayer

signal difficulty_selected(difficulty: int)
signal popup_closed

# Константы сложностей
const DIFFICULTY_RECRUIT: int = 0
const DIFFICULTY_VETERAN: int = 1
const DIFFICULTY_LEGEND: int = 2

# Цвета рамок для кнопок
const COLOR_RECRUIT: Color = Color(0.2, 0.7, 1.0, 1.0)
const COLOR_VETERAN: Color = Color(0.7, 0.2, 1.0, 1.0)
const COLOR_LEGEND: Color = Color(0.7, 0.05, 0.05, 1.0)
const COLOR_LOCKED: Color = Color(0.3, 0.3, 0.3, 0.6)

@onready var recruit_button: Button = $Panel/VBox/RecruitButton
@onready var veteran_button: Button = $Panel/VBox/VeteranButton
@onready var legend_button: Button = $Panel/VBox/LegendButton
@onready var close_button: Button = $Panel/CloseButton
@onready var title_label: Label = $Panel/TitleLabel
@onready var description_label: Label = $Panel/DescriptionLabel

@onready var panel: Panel = $Panel
@onready var panel_settings: Panel = $Panelsettings
@onready var setting_button: Button = $Panel/VBox/VBoxContainer/SettingButton
@onready var panel_settings_close: Button = $Panelsettings/CloseButton

var _difficulty_unlocked: Array = [0]

@onready var panel_settings_title: Label = $Panelsettings/Label
@onready var panel_settings_phantom: Label = $Panelsettings/Label2
@onready var panel_settings_shockwave: Label = $Panelsettings/Label3
@onready var panel_settings_shockwave_act: Label = $Panelsettings/Label4
@onready var panel_settings_homing: Label = $Panelsettings/Label5
@onready var panel_settings_homing_act: Label = $Panelsettings/Label6
@onready var panel_settings_goliath: Label = $Panelsettings/Label7
@onready var panel_settings_goliath_act: Label = $Panelsettings/Label8


func _ready() -> void:
	print("[DiffSelect] _ready() вызван")
	
	_difficulty_unlocked = [0]
	
	var sm := get_node_or_null("/root/SaveManager")
	if sm:
		if "difficulty_unlocked" in sm and sm.difficulty_unlocked is Array and sm.difficulty_unlocked.size() > 0:
			_difficulty_unlocked = sm.difficulty_unlocked.duplicate()
			# Очищаем дубли и приводим к int
			var clean: Array = []
			for v in _difficulty_unlocked:
				var val = int(v)
				if not val in clean:
					clean.append(val)
			_difficulty_unlocked = clean
		
		# Рекрут (0) всегда разблокирован
		if not 0 in _difficulty_unlocked:
			_difficulty_unlocked.insert(0, 0)
		
		# Проверяем ачивку "Непобедимый" — если есть, разблокируем Ветеран
		if sm.is_achievement_unlocked("invincible"):
			if not 1 in _difficulty_unlocked:
				_difficulty_unlocked.append(1)
				print("[DiffSelect] Ветеран разблокирован по ачивке")
		
		# Синхронизируем с сохранением (но не вызываем save на каждый чих)
		sm.difficulty_unlocked = _difficulty_unlocked.duplicate()
	
	print("[DiffSelect] _difficulty_unlocked = " + str(_difficulty_unlocked))
	
	_setup_localization()
	_setup_buttons()
	_setup_styles()
	
	# Используем func() вместо bind() для надёжности
	recruit_button.pressed.connect(_on_recruit_pressed)
	veteran_button.pressed.connect(_on_veteran_pressed)
	legend_button.pressed.connect(_on_legend_pressed)
	close_button.pressed.connect(_on_close_pressed)

	# === Настройки ===
	panel_settings.visible = false
	panel.visible = true
	setting_button.pressed.connect(_on_setting_button_pressed)
	panel_settings_close.pressed.connect(_on_panel_settings_close_pressed)
	
	# Подписываемся на смену языка
	if LocalizationManager.language_changed.is_connected(_on_language_changed):
		LocalizationManager.language_changed.disconnect(_on_language_changed)
	LocalizationManager.language_changed.connect(_on_language_changed)
	
	_on_button_hover(DIFFICULTY_RECRUIT)
	
	recruit_button.mouse_entered.connect(_on_button_hover.bind(DIFFICULTY_RECRUIT))
	veteran_button.mouse_entered.connect(_on_button_hover.bind(DIFFICULTY_VETERAN))
	legend_button.mouse_entered.connect(_on_button_hover.bind(DIFFICULTY_LEGEND))


func _setup_localization() -> void:
	title_label.text = tr("diff_title")
	setting_button.text = tr("diff_setting")
	if panel_settings_title:
		panel_settings_title.text = tr("diff_controls_title")
	if panel_settings_phantom:
		panel_settings_phantom.text = tr("diff_phantom_desc")
	if panel_settings_shockwave:
		panel_settings_shockwave.text = tr("diff_shockwave_desc")
	if panel_settings_shockwave_act:
		panel_settings_shockwave_act.text = tr("diff_shockwave_act")
	if panel_settings_homing:
		panel_settings_homing.text = tr("diff_homing_desc")
	if panel_settings_homing_act:
		panel_settings_homing_act.text = tr("diff_homing_act")
	if panel_settings_goliath:
		panel_settings_goliath.text = tr("diff_goliath_desc")
	if panel_settings_goliath_act:
		panel_settings_goliath_act.text = tr("diff_goliath_act")
	_setup_buttons()
	_on_button_hover(DIFFICULTY_RECRUIT)


func _on_language_changed(_locale: String) -> void:
	_setup_localization()


func _on_recruit_pressed() -> void:
	await _start_game(DIFFICULTY_RECRUIT)


func _on_veteran_pressed() -> void:
	await _start_game(DIFFICULTY_VETERAN)


func _on_legend_pressed() -> void:
	await _start_game(DIFFICULTY_LEGEND)


func _start_game(difficulty: int) -> void:
	print("[DiffSelect] _start_game(" + str(difficulty) + ")")
	
	if not difficulty in _difficulty_unlocked:
		print("[DiffSelect] Сложность " + str(difficulty) + " не разблокирована")
		return
	
	var sm := get_node_or_null("/root/SaveManager")
	if sm:
		sm.difficulty_level = difficulty
		sm.save_game()
		print("[DiffSelect] Сохранено difficulty_level = " + str(difficulty))
	
	# Если реклама доступна — показываем и ждём закрытия
	var ads = get_node_or_null("/root/AdsManager")
	if ads != null and ads.has_method("can_show_interstitial") and ads.can_show_interstitial():
		ads.queue_interstitial()
		await ads.queue_completed
	
	# Переход в игру после рекламы
	var tree = get_tree()
	if tree:
		tree.change_scene_to_file("res://levels/Main.tscn")


func _setup_buttons() -> void:
	recruit_button.text = tr("diff_recruit")
	
	if DIFFICULTY_VETERAN in _difficulty_unlocked:
		veteran_button.text = tr("diff_veteran")
		veteran_button.disabled = false
	else:
		veteran_button.text = "???"
		veteran_button.disabled = true
	
	if DIFFICULTY_LEGEND in _difficulty_unlocked:
		legend_button.text = tr("diff_legend")
		legend_button.disabled = false
	else:
		legend_button.text = "???"
		legend_button.disabled = true


func _setup_styles() -> void:
	_apply_difficulty_style(recruit_button, COLOR_RECRUIT, true)
	_apply_difficulty_style(veteran_button, COLOR_VETERAN, DIFFICULTY_VETERAN in _difficulty_unlocked)
	_apply_difficulty_style(legend_button, COLOR_LEGEND, DIFFICULTY_LEGEND in _difficulty_unlocked)
	_apply_difficulty_style(setting_button, COLOR_RECRUIT, true)


func _apply_difficulty_style(btn: Button, border_color: Color, unlocked: bool) -> void:
	if not btn:
		return
	
	var bg_color := Color(0.0, 0.0, 0.0, 0.8)
	var bg_hover := Color(0.05, 0.05, 0.1, 0.85)
	var bg_pressed := Color(0.02, 0.02, 0.05, 0.9)
	
	if not unlocked:
		bg_color = Color(0.0, 0.0, 0.0, 0.5)
		bg_hover = Color(0.0, 0.0, 0.0, 0.5)
		bg_pressed = Color(0.0, 0.0, 0.0, 0.5)
		border_color = COLOR_LOCKED
	
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg_color
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	normal.border_width_left = 2
	normal.border_width_right = 2
	normal.border_width_top = 2
	normal.border_width_bottom = 2
	normal.border_color = border_color
	btn.add_theme_stylebox_override("normal", normal)
	
	var hover := StyleBoxFlat.new()
	hover.bg_color = bg_hover
	hover.corner_radius_top_left = 8
	hover.corner_radius_top_right = 8
	hover.corner_radius_bottom_left = 8
	hover.corner_radius_bottom_right = 8
	hover.content_margin_left = 16
	hover.content_margin_right = 16
	hover.content_margin_top = 8
	hover.content_margin_bottom = 8
	hover.border_width_left = 2
	hover.border_width_right = 2
	hover.border_width_top = 2
	hover.border_width_bottom = 2
	if unlocked:
		var lighter := Color(border_color.r * 1.3, border_color.g * 1.3, border_color.b * 1.3, 1.0)
		hover.border_color = lighter
	else:
		hover.border_color = COLOR_LOCKED
	btn.add_theme_stylebox_override("hover", hover)
	
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = bg_pressed
	pressed.corner_radius_top_left = 8
	pressed.corner_radius_top_right = 8
	pressed.corner_radius_bottom_left = 8
	pressed.corner_radius_bottom_right = 8
	pressed.content_margin_left = 16
	pressed.content_margin_right = 16
	pressed.content_margin_top = 8
	pressed.content_margin_bottom = 8
	pressed.border_width_left = 2
	pressed.border_width_right = 2
	pressed.border_width_top = 2
	pressed.border_width_bottom = 2
	pressed.border_color = Color(border_color.r * 0.6, border_color.g * 0.6, border_color.b * 0.6, 0.8)
	btn.add_theme_stylebox_override("pressed", pressed)
	
	if not unlocked:
		var disabled := StyleBoxFlat.new()
		disabled.bg_color = Color(0.0, 0.0, 0.0, 0.5)
		disabled.corner_radius_top_left = 8
		disabled.corner_radius_top_right = 8
		disabled.corner_radius_bottom_left = 8
		disabled.corner_radius_bottom_right = 8
		disabled.content_margin_left = 16
		disabled.content_margin_right = 16
		disabled.content_margin_top = 8
		disabled.content_margin_bottom = 8
		disabled.border_width_left = 2
		disabled.border_width_right = 2
		disabled.border_width_top = 2
		disabled.border_width_bottom = 2
		disabled.border_color = COLOR_LOCKED
		btn.add_theme_stylebox_override("disabled", disabled)
		btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5, 0.6))
	
	if unlocked:
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_color_override("font_hover_color", border_color)
	else:
		btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.6))
	
	btn.add_theme_font_size_override("font_size", 28)


func _on_button_hover(difficulty: int) -> void:
	var is_unlocked := difficulty in _difficulty_unlocked
	if is_unlocked:
		match difficulty:
			DIFFICULTY_RECRUIT:
				description_label.text = tr("diff_recruit_desc")
			DIFFICULTY_VETERAN:
				description_label.text = tr("diff_veteran_desc")
			DIFFICULTY_LEGEND:
				description_label.text = tr("diff_legend_desc")
	else:
		match difficulty:
			DIFFICULTY_VETERAN:
				description_label.text = tr("diff_veteran_locked")
			DIFFICULTY_LEGEND:
				description_label.text = tr("diff_legend_locked")


func _on_setting_button_pressed() -> void:
	panel.visible = false
	panel_settings.visible = true


func _on_panel_settings_close_pressed() -> void:
	panel_settings.visible = false
	panel.visible = true


func _on_close_pressed() -> void:
	popup_closed.emit()
	queue_free()
