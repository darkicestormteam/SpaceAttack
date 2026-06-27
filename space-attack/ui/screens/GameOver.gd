extends CanvasLayer

## Экран поражения.

const DOUBLE_CREDITS_POPUP: PackedScene = preload("res://ui/popups/DoubleCreditsPopup.tscn")

@onready var score_label: Label = %ScoreLabel
@onready var credits_label: Label = %CreditsLabel
@onready var restart_btn: Button = %RestartButton
@onready var quit_btn: Button = %QuitButton
@onready var revive_btn: Button = %ReviveButton

var _credits_earned: int = 0
var _has_revived: bool = false
var _is_action_pending: bool = false


func _ready() -> void:
	restart_btn.pressed.connect(_on_restart_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	revive_btn.pressed.connect(_on_revive_pressed)


func set_stats(final_score: int, final_credits: int, earned: int = 0) -> void:
	score_label.text = "Очки: " + str(final_score)
	_credits_earned = earned
	credits_label.text = "Заработано кредитов: " + str(_credits_earned)


# ============================================================
# Воскрешение
# ============================================================

func _on_revive_pressed() -> void:
	if _has_revived or _is_action_pending:
		return
	_is_action_pending = true
	
	revive_btn.disabled = true
	revive_btn.text = "Загрузка..."
	
	var ads = get_node_or_null("/root/AdsManager") as Node
	var got_reward = false
	if ads != null and ads.has_method("show_rewarded_and_wait"):
		got_reward = await ads.show_rewarded_and_wait()
	else:
		got_reward = false
	
	_is_action_pending = false
	
	if got_reward:
		_has_revived = true
		revive_btn.text = "Воскрешён ✓"
		revive_btn.disabled = true
		var main = get_tree().current_scene
		if main and main.has_method("revive_player"):
			main.revive_player()
	else:
		revive_btn.text = "Воскреснуть за рекламу"
		revive_btn.disabled = false


# ============================================================
# "Заново" — с попапом удвоения
# ============================================================

func _on_restart_pressed() -> void:
	if _is_action_pending:
		return
	_is_action_pending = true
	
	if _credits_earned > 0:
		await _show_double_credits_popup()
	
	get_tree().paused = false
	get_tree().reload_current_scene()


# ============================================================
# "Выход" — с попапом удвоения
# ============================================================

func _on_quit_pressed() -> void:
	if _is_action_pending:
		return
	_is_action_pending = true
	
	if _credits_earned > 0:
		await _show_double_credits_popup()
	
	get_tree().paused = false
	_show_ad_and_go_hangar()


# ============================================================
# Показ попапа удвоения кредитов
# ============================================================

func _show_double_credits_popup() -> void:
	# Прячем фон и кнопки GameOver на время попапа
	if has_node("Background"):
		$Background.visible = false
	if has_node("VBox"):
		$VBox.visible = false
	
	var popup = DOUBLE_CREDITS_POPUP.instantiate()
	add_child(popup)
	popup.setup(_credits_earned)
	await popup.action_completed
	if is_instance_valid(popup):
		popup.queue_free()
	
	# Возвращаем фон и кнопки
	if has_node("Background"):
		$Background.visible = true
	if has_node("VBox"):
		$VBox.visible = true


# ============================================================
# Межстраничная реклама + переход в ангар
# ============================================================

func _show_ad_and_go_hangar() -> void:
	var ads = get_node_or_null("/root/AdsManager") as Node
	if ads != null and ads.has_method("can_show_interstitial"):
		await ads.show_interstitial_and_wait()
	get_tree().change_scene_to_file("res://ui/screens/Hangar.tscn")
