extends CanvasLayer

## Попап: "Вы заработали X кредитов. Удвоить?"
## Эмитит choice_made. Вызывающий скрипт сам вызывает рекламу.

signal choice_made(choice: String)  # "yes" или "no"
signal popup_closed

var _credits_earned: int = 0
var _action_chosen: bool = false

@onready var credits_label: Label = %CreditsLabel
@onready var yes_btn: Button = %YesButton
@onready var no_btn: Button = %NoButton


func _ready() -> void:
	yes_btn.pressed.connect(_on_yes_pressed)
	no_btn.pressed.connect(_on_no_pressed)
	_apply_button_style(yes_btn)
	_apply_button_style(no_btn)
	_setup_localization()
	if LocalizationManager.language_changed.is_connected(_on_language_changed):
		LocalizationManager.language_changed.disconnect(_on_language_changed)
	LocalizationManager.language_changed.connect(_on_language_changed)


func _setup_localization() -> void:
	if _credits_earned > 0:
		credits_label.text = tr("double_earned") % _credits_earned
	yes_btn.text = tr("double_yes")
	no_btn.text = tr("double_no")
	# Обновляем заголовок и подпись
	var title_label: Label = get_node_or_null("PopupVBox/TitleLabel")
	if title_label:
		title_label.text = tr("double_title")
	var sub_label: Label = get_node_or_null("PopupVBox/SubLabel")
	if sub_label:
		sub_label.text = tr("double_sub")


func _on_language_changed(_locale: String) -> void:
	_setup_localization()


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
	normal.content_margin_left = 24
	normal.content_margin_right = 24
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
	hover.content_margin_left = 24
	hover.content_margin_right = 24
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
	pressed.content_margin_left = 24
	pressed.content_margin_right = 24
	pressed.content_margin_top = 8
	pressed.content_margin_bottom = 8
	btn.add_theme_stylebox_override("pressed", pressed)


func setup(credits_earned: int) -> void:
	_credits_earned = credits_earned
	credits_label.text = tr("double_earned") % credits_earned


func _on_yes_pressed() -> void:
	if _action_chosen:
		return
	_action_chosen = true
	
	choice_made.emit("yes")
	popup_closed.emit()
	visible = false


func _on_no_pressed() -> void:
	if _action_chosen:
		return
	_action_chosen = true
	
	choice_made.emit("no")
	popup_closed.emit()
	visible = false


func reset() -> void:
	_action_chosen = false
	yes_btn.disabled = false
	no_btn.disabled = false
	yes_btn.text = tr("double_yes_ad")
