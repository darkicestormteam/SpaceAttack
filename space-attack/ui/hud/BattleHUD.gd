extends CanvasLayer

@onready var score_label: Label = %ScoreLabel
@onready var credits_label: Label = %CreditsLabel
@onready var wave_label: Label = $WaveLabel
@onready var lives_label: Label = %LivesLabel
@onready var shockwave_button: Button = %ShockwaveButton
@onready var shockwave_cooldown_label: Label = %ShockwaveCooldownLabel

var _player: Node = null


func _ready() -> void:
	if shockwave_button:
		shockwave_button.pressed.connect(_on_shockwave_pressed)
	_update_shockwave_button_visibility()


func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_try_find_player()
	_update_cooldown_label()


func _try_find_player() -> void:
	# Ищем Player на сцене (он может появиться после _ready HUD)
	var scene := get_tree().current_scene
	if scene == null:
		return
	var p := scene.find_child("Player", true, false)
	if p != null:
		_player = p
		# Подключаемся к сигналам игрока
		if not p.shockwave_used.is_connected(_on_shockwave_used):
			p.shockwave_used.connect(_on_shockwave_used)
		if not p.shockwave_ready.is_connected(_on_shockwave_ready):
			p.shockwave_ready.connect(_on_shockwave_ready)
		_update_shockwave_button_visibility()


func _update_shockwave_button_visibility() -> void:
	if shockwave_button == null:
		return
	if _player == null:
		shockwave_button.visible = false
		shockwave_cooldown_label.visible = false
		return
	# Кнопка видна только если модуль экипирован
	shockwave_button.visible = _player.has_shockwave_module
	shockwave_cooldown_label.visible = _player.has_shockwave_module


func _update_cooldown_label() -> void:
	if shockwave_cooldown_label == null or _player == null:
		return
	if not shockwave_cooldown_label.visible:
		return
	if _player.shockwave_cooldown <= 0.0:
		shockwave_cooldown_label.text = "Готово (F)"
		shockwave_cooldown_label.modulate = Color(0.5, 1, 0.5, 1)
		shockwave_button.disabled = false
		shockwave_button.modulate = Color(1, 1, 1, 1)
	else:
		var cd: float = _player.shockwave_cooldown
		shockwave_cooldown_label.text = "⏳ %.1f с" % cd
		shockwave_cooldown_label.modulate = Color(1, 0.6, 0.4, 1)
		shockwave_button.disabled = true
		shockwave_button.modulate = Color(0.6, 0.6, 0.6, 1)


func _on_shockwave_pressed() -> void:
	if _player != null and _player.has_method("try_activate_shockwave"):
		_player.try_activate_shockwave()


func _on_shockwave_used() -> void:
	# Можно добавить звук/анимацию
	pass


func _on_shockwave_ready() -> void:
	# Можно добавить звук "готово"
	pass


func update_score(value: int) -> void:
	score_label.text = "Очки: " + str(value)


func update_credits(value: int) -> void:
	credits_label.text = "Кредиты: " + str(value)


func update_lives(value: int) -> void:
	if lives_label != null:
		lives_label.text = "❤️ " + str(value)


func update_wave(value: int) -> void:
	wave_label.text = "Wave: " + str(value)
