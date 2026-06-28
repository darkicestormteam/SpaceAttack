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
	
	var should_double := false
	if _credits_earned > 0:
		should_double = await _show_double_credits_popup()
	
	var ads = get_node_or_null("/root/AdsManager") as Node
	if ads:
		if should_double:
			ads.queue_rewarded_double(_credits_earned)
		else:
			ads.queue_interstitial()
		
		# SAFE TIMEOUT: Max 5 seconds wait for ad to start
		var timeout := get_tree().create_timer(5.0)
		while not ads.is_ad_showing and timeout.get_time_left() > 0.0:
			await get_tree().process_frame
		# If ad started showing, wait for it to close
		if ads.is_ad_showing:
			await ads.queue_completed
	
	get_tree().paused = false
	get_tree().reload_current_scene()


# ============================================================
# "Выход" — с попапом удвоения + реклама через очередь + ангар
# ============================================================

func _on_quit_pressed() -> void:
	if _is_action_pending:
		return
	_is_action_pending = true
	
	var ads = get_node_or_null("/root/AdsManager") as Node
	if ads == null or not ads.has_method("queue_interstitial"):
		get_tree().paused = false
		get_tree().change_scene_to_file("res://ui/screens/Hangar.tscn")
		return
	
	# Отключаем кнопки, чтобы игрок не нажал повторно
	quit_btn.disabled = true
	restart_btn.disabled = true
	revive_btn.disabled = true
	
	var was_paused = get_tree().paused
	var popup = null
	
	if _credits_earned > 0:
		# Показываем попап удвоения
		popup = DOUBLE_CREDITS_POPUP.instantiate()
		add_child(popup)
		popup.setup(_credits_earned)
		
		# Ожидаем выбор игрока
		var choice = await popup.choice_made
		
		if choice == "yes":
			ads.queue_rewarded_double(_credits_earned)
		else:
			ads.queue_interstitial()
	else:
		ads.queue_interstitial()
	
	# Ждём завершения всей очереди
	await ads.queue_completed
	
	# Закрываем попап, если ещё висит
	if popup != null and is_instance_valid(popup):
		popup.queue_free()
	
	# Переход в ангар — всегда снимаем паузу, чтобы Hangar не загрузился замёрзшим
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/screens/Hangar.tscn")


# ============================================================
# Показ попапа удвоения кредитов (для рестарта — без рекламы)
# ============================================================

func _show_double_credits_popup() -> bool:
	# Прячем фон и кнопки GameOver на время попапа
	if has_node("Background"):
		$Background.visible = false
	if has_node("VBox"):
		$VBox.visible = false
	
	var popup = DOUBLE_CREDITS_POPUP.instantiate()
	add_child(popup)
	popup.setup(_credits_earned)
	
	# Ждём выбора (choice_made эмитится и при "yes" и при "no")
	var choice = await popup.choice_made
	
	if is_instance_valid(popup):
		popup.queue_free()
	
	# Возвращаем фон и кнопки
	if has_node("Background"):
		$Background.visible = true
	if has_node("VBox"):
		$VBox.visible = true
	
	return choice == "yes"
