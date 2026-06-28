extends CanvasLayer

## Анимация перетекания: бонус → баланс. Кнопка "Принять" закрывает окно.
## Начисление кредитов происходит ДО показа анимации.

signal credits_accepted()

@onready var main_balance_label: Label = %MainBalanceLabel
@onready var bonus_label: Label = %BonusLabel
@onready var accept_button: Button = %AcceptButton

var _amount: int = 0
var _old_balance: int = 0


func _ready() -> void:
	_apply_button_style(accept_button)


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


func setup(amount: int) -> void:
	_amount = amount
	_old_balance = SaveManager.credits - amount
	main_balance_label.text = "Баланс: %d" % _old_balance
	bonus_label.text = "+%d" % amount
	
	accept_button.visible = true
	accept_button.pressed.connect(_on_accept_pressed)
	
	# Запуск анимации сразу
	start_animation()


func start_animation() -> void:
	var target_balance = SaveManager.credits
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_method(_update_animation, 0.0, 1.0, 2.0)
	# Кнопка остаётся видимой всё время


func _update_animation(progress: float) -> void:
	var current_bonus = int(ceil(float(_amount) * (1.0 - progress)))
	var current_balance = int(_old_balance + float(_amount) * progress)
	bonus_label.text = "+%d" % max(0, current_bonus)
	main_balance_label.text = "Баланс: %d" % current_balance


func _on_accept_pressed() -> void:
	accept_button.visible = false
	accept_button.disabled = true
	credits_accepted.emit()
	queue_free()
