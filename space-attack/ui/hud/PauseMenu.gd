extends CanvasLayer

## Универсальное меню: пауза / game over / победа.
## Заменяет GameOver.tscn и VictoryScreen.tscn.

enum Mode { PAUSED, GAME_OVER, VICTORY }

signal resumed
signal restart_requested
signal hangar_requested
signal revive_requested

@onready var menu_button: Button = %MenuButton
@onready var dim: ColorRect = %Dim
@onready var panel: VBoxContainer = %MenuPanel
@onready var settings_panel: VBoxContainer = %SettingsPanel

@onready var title_label: Label = %TitleLabel
@onready var score_label: Label = %ScoreLabel
@onready var credits_label: Label = %CreditsLabel
@onready var revive_button: Button = %ReviveButton
@onready var resume_button: Button = %ResumeButton
@onready var hangar_button: Button = %HangarButton
@onready var restart_button: Button = %RestartButton
@onready var settings_button: Button = %SettingsButton

@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var music_label: Label = %MusicLabel
@onready var sfx_label: Label = %SfxLabel

var _current_mode: Mode = Mode.PAUSED
var _last_score: int = 0
var _last_credits: int = 0


func _setup_localization() -> void:
	_sync_settings_sliders()
	
	resume_button.text = tr("pause_resume")
	hangar_button.text = tr("pause_hangar")
	restart_button.text = tr("pause_restart")
	settings_button.text = tr("pause_settings")
	menu_button.text = tr("settings_btn")
	%SettingsBackButton.text = tr("pause_settings_back")
	
	var settings_title: Label = settings_panel.get_node("SettingsTitle")
	if settings_title:
		settings_title.text = tr("pause_settings_title")
	
	if _current_mode == Mode.PAUSED:
		title_label.text = tr("pause_title")
	elif _current_mode == Mode.GAME_OVER:
		title_label.text = tr("defeat_title")
		score_label.text = tr("pause_score") % _last_score
		credits_label.text = tr("pause_credits_earned") % _last_credits
		revive_button.text = tr("pause_revive_ad") if not revive_button.disabled else tr("pause_revive_unavailable")
	elif _current_mode == Mode.VICTORY:
		title_label.text = tr("victory_title")
		score_label.text = tr("pause_score") % _last_score
		credits_label.text = tr("pause_credits") % _last_credits
	_update_volume_labels()


func _on_language_changed(_locale: String) -> void:
	_setup_localization()


func _ready() -> void:
	_apply_all_button_styles()
	_setup_localization()
	
	if LocalizationManager.language_changed.is_connected(_on_language_changed):
		LocalizationManager.language_changed.disconnect(_on_language_changed)
	LocalizationManager.language_changed.connect(_on_language_changed)
	
	resume_button.pressed.connect(_on_resume_pressed)
	hangar_button.pressed.connect(_on_hangar_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	settings_button.pressed.connect(_show_settings)
	revive_button.pressed.connect(_on_revive_pressed)
	%SettingsBackButton.pressed.connect(_hide_settings)
	menu_button.pressed.connect(_on_menu_button_pressed)
	
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	
	hide_menu()


# ============================================================
# Переключение режимов
# ============================================================

## Установить режим и показать меню.
func show_mode(mode: Mode, score: int = 0, credits_earned: int = 0, can_revive: bool = true) -> void:
	_current_mode = mode
	_last_score = score
	_last_credits = credits_earned
	dim.visible = true
	panel.visible = true
	menu_button.visible = false
	get_tree().paused = true
	
	match mode:
		Mode.PAUSED:
			title_label.text = tr("pause_title")
			score_label.visible = false
			credits_label.visible = false
			revive_button.visible = false
			resume_button.visible = true
			hangar_button.visible = true
			restart_button.visible = true
			settings_button.visible = true
			
		Mode.GAME_OVER:
			title_label.text = tr("defeat_title")
			score_label.visible = true
			score_label.text = tr("pause_score") % score
			credits_label.visible = true
			credits_label.text = tr("pause_credits_earned") % credits_earned
			revive_button.visible = can_revive
			revive_button.text = tr("pause_revive_ad") if can_revive else tr("pause_revive_unavailable")
			revive_button.disabled = not can_revive
			resume_button.visible = false
			hangar_button.visible = true
			restart_button.visible = true
			settings_button.visible = false
			
		Mode.VICTORY:
			title_label.text = tr("victory_title")
			score_label.visible = true
			score_label.text = tr("pause_score") % score
			credits_label.visible = true
			credits_label.text = tr("pause_credits") % credits_earned
			revive_button.visible = false
			resume_button.visible = false
			hangar_button.visible = true
			restart_button.visible = true
			settings_button.visible = false


func _gameplay_pause() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("on_game_paused"):
		gm.on_game_paused()


func _gameplay_resume() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("on_game_resumed"):
		gm.on_game_resumed()


func show_menu() -> void:
	_gameplay_pause()
	show_mode(Mode.PAUSED)


## Скрыть меню.
## release_pause=true — снять паузу (для кнопки "Продолжить")
## release_pause=false — пауза остаётся (для воскрешения, Main сам снимет)
func hide_menu(release_pause: bool = false) -> void:
	dim.visible = false
	panel.visible = false
	settings_panel.visible = false
	menu_button.visible = true
	if release_pause:
		get_tree().paused = false
		_gameplay_resume()


# ============================================================
# Стили кнопок
# ============================================================

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
	normal.corner_radius_top_left = 10
	normal.corner_radius_top_right = 10
	normal.corner_radius_bottom_left = 10
	normal.corner_radius_bottom_right = 10
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", normal)
	
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.15, 0.2, 0.35, 0.85)
	hover.border_width_left = 2
	hover.border_width_top = 2
	hover.border_width_right = 2
	hover.border_width_bottom = 2
	hover.border_color = Color(0.5, 0.85, 1, 1)
	hover.corner_radius_top_left = 10
	hover.corner_radius_top_right = 10
	hover.corner_radius_bottom_left = 10
	hover.corner_radius_bottom_right = 10
	hover.content_margin_left = 16
	hover.content_margin_right = 16
	hover.content_margin_top = 8
	hover.content_margin_bottom = 8
	btn.add_theme_stylebox_override("hover", hover)
	
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(0.05, 0.08, 0.15, 0.9)
	pressed.border_width_left = 2
	pressed.border_width_top = 2
	pressed.border_width_right = 2
	pressed.border_width_bottom = 2
	pressed.border_color = Color(0.2, 0.4, 0.7, 1)
	pressed.corner_radius_top_left = 10
	pressed.corner_radius_top_right = 10
	pressed.corner_radius_bottom_left = 10
	pressed.corner_radius_bottom_right = 10
	pressed.content_margin_left = 16
	pressed.content_margin_right = 16
	pressed.content_margin_top = 8
	pressed.content_margin_bottom = 8
	btn.add_theme_stylebox_override("pressed", pressed)


func _apply_mini_button_style(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.0, 0.0, 0.0, 0.5)
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(0.3, 0.6, 1, 0.7)
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", normal)
	
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.15, 0.2, 0.35, 0.7)
	hover.border_width_left = 2
	hover.border_width_top = 2
	hover.border_width_right = 2
	hover.border_width_bottom = 2
	hover.border_color = Color(0.5, 0.85, 1, 0.9)
	hover.corner_radius_top_left = 8
	hover.corner_radius_top_right = 8
	hover.corner_radius_bottom_left = 8
	hover.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("hover", hover)


func _apply_all_button_styles() -> void:
	_apply_button_style(resume_button)
	_apply_button_style(hangar_button)
	_apply_button_style(restart_button)
	_apply_button_style(settings_button)
	_apply_button_style(revive_button)
	_apply_button_style(%SettingsBackButton)
	_apply_mini_button_style(menu_button)


# ============================================================
# Настройки
# ============================================================

func _sync_settings_sliders() -> void:
	var am := get_node_or_null("/root/AudioManager") as Node
	if am == null:
		return
	music_slider.value = am.music_volume
	sfx_slider.value = am.sfx_volume
	_update_volume_labels()
	
	
func _update_volume_labels() -> void:
	music_label.text = tr("pause_music_label") % int(music_slider.value * 100.0)
	sfx_label.text = tr("pause_sfx_label") % int(sfx_slider.value * 100.0)


func _show_settings() -> void:
	_sync_settings_sliders()
	panel.visible = false
	settings_panel.visible = true


func _hide_settings() -> void:
	settings_panel.visible = false
	panel.visible = true


func _on_music_volume_changed(value: float) -> void:
	var am := get_node_or_null("/root/AudioManager")
	if am and am.has_method(&"set_music_volume_direct"):
		am.set_music_volume_direct(value)
	_update_volume_labels()


func _on_sfx_volume_changed(value: float) -> void:
	var am := get_node_or_null("/root/AudioManager")
	if am and am.has_method(&"set_sfx_volume_direct"):
		am.set_sfx_volume_direct(value)
	_update_volume_labels()


func _on_music_toggle_pressed() -> void:
	var am := get_node_or_null("/root/AudioManager") as Node
	if am and am.has_method(&"toggle_music"):
		am.toggle_music()
	_sync_settings_sliders()


func _on_sfx_toggle_pressed() -> void:
	var am := get_node_or_null("/root/AudioManager") as Node
	if am and am.has_method(&"toggle_sfx"):
		am.toggle_sfx()
	_sync_settings_sliders()


# ============================================================
# Обработчики кнопок
# ============================================================

func _on_menu_button_pressed() -> void:
	show_menu()


func _on_resume_pressed() -> void:
	hide_menu(true)
	resumed.emit()


func _transfer_credits_to_pending() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if sm:
		if sm.session_credits_bank > 0:
			sm.pending_double_credits = sm.session_credits_bank
			sm.session_credits_bank = 0


func _on_hangar_pressed() -> void:
	_transfer_credits_to_pending()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/screens/Hangar.tscn")


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_revive_pressed() -> void:
	revive_requested.emit()
