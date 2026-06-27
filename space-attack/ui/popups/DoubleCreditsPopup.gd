extends CanvasLayer

## Универсальный попап: "Вы заработали X кредитов. Удвоить за рекламу?"
## Может использоваться как встроенный в сцену (visible = false),
## так и создаваться через instantiate().

signal action_completed(doubled: bool)
signal popup_closed

var _credits_earned: int = 0
var _is_loading: bool = false
var _action_chosen: bool = false

@onready var credits_label: Label = %CreditsLabel
@onready var yes_btn: Button = %YesButton
@onready var no_btn: Button = %NoButton


func _ready() -> void:
	yes_btn.pressed.connect(_on_yes_pressed)
	no_btn.pressed.connect(_on_no_pressed)
	# Dim перехватывает клики
	for child in get_children():
		if child is ColorRect and child.name == "Dim":
			child.mouse_filter = Control.MOUSE_FILTER_STOP


func setup(credits_earned: int) -> void:
	_credits_earned = credits_earned
	credits_label.text = "Вы заработали %d кредитов!\nХотите удвоить за просмотр рекламы?" % credits_earned


func _on_yes_pressed() -> void:
	if _action_chosen or _is_loading:
		return
	_action_chosen = true
	_is_loading = true
	
	yes_btn.disabled = true
	no_btn.disabled = true
	yes_btn.text = "Загрузка..."
	
	var ads = get_node_or_null("/root/AdsManager") as Node
	var got_reward = false
	if ads != null and ads.has_method("show_rewarded_and_wait"):
		got_reward = await ads.show_rewarded_and_wait()
	
	if got_reward:
		SaveManager.credits += _credits_earned
		SaveManager.save_game()
		print("[DoubleCreditsPopup] Credits doubled! +%d" % _credits_earned)
	
	action_completed.emit(got_reward)
	popup_closed.emit()
	visible = false


func _on_no_pressed() -> void:
	if _action_chosen:
		return
	_action_chosen = true
	
	action_completed.emit(false)
	popup_closed.emit()
	visible = false


## Сброс для повторного использования (если попап встроен в сцену)
func reset() -> void:
	_action_chosen = false
	_is_loading = false
	yes_btn.disabled = false
	no_btn.disabled = false
	yes_btn.text = "Да, удвоить за рекламу"