extends CanvasLayer

@onready var score_label: Label = %ScoreLabel
@onready var credits_label: Label = %CreditsLabel
@onready var wave_label: Label = $WaveLabel
@onready var lives_label: Label = %LivesLabel

# Контейнер с кнопками скиллов
@onready var skill_container: HBoxContainer = $HBoxContainer

# Shockwave
@onready var shockwave_container: VBoxContainer = $HBoxContainer/ShockwaveContainer
@onready var shockwave_label: Label = $HBoxContainer/ShockwaveContainer/ShockwaveCooldownLabel
@onready var shockwave_button: TextureButton = $HBoxContainer/ShockwaveContainer/ShockwaveButton

# Goliath Charge (пробелы в именах — через get_node)
@onready var goliath_container: VBoxContainer = get_node("HBoxContainer/Goliath Charge")
@onready var goliath_label: Label = get_node("HBoxContainer/Goliath Charge/Goliath ChargeCooldownLabel")
@onready var goliath_button: TextureButton = get_node("HBoxContainer/Goliath Charge/Goliath ChargeButton")

# Homing Salvo
@onready var homing_container: VBoxContainer = get_node("HBoxContainer/Homing Salvo")
@onready var homing_label: Label = get_node("HBoxContainer/Homing Salvo/Homing Salvo")
@onready var homing_button: TextureButton = get_node("HBoxContainer/Homing Salvo/Homing SalvoButton")

# Phantom Dash
@onready var dash_container: VBoxContainer = get_node("HBoxContainer/PhantomDash")
@onready var dash_label: Label = get_node("HBoxContainer/PhantomDash/PhantomDashCooldownLabel")
@onready var dash_button: TextureButton = get_node("HBoxContainer/PhantomDash/PhantomDashButton")

@onready var anim_shockwave: AnimationPlayer = $AnimationPlayer_Shockwave
@onready var anim_goliath: AnimationPlayer = $AnimationPlayer_Goliath
@onready var anim_homing: AnimationPlayer = $AnimationPlayer_Homing
@onready var anim_dash: AnimationPlayer = $AnimationPlayer_Dash
@onready var music_toggle: TextureButton = $TopBar/MusicToggle
@onready var sfx_toggle: TextureButton = $TopBar/SfxToggle

var _player: Node = null



func _ready() -> void:
	if shockwave_button:
		shockwave_button.texture_normal = load("res://assets/icons/skils/Shockwave.png")
		shockwave_button.pressed.connect(_on_shockwave_pressed)
	if goliath_button:
		goliath_button.texture_normal = load("res://assets/icons/skils/Goliath Charge.png")
		goliath_button.pressed.connect(_on_goliath_pressed)
	if homing_button:
		homing_button.texture_normal = load("res://assets/icons/skils/Homing Salvo.png")
		homing_button.pressed.connect(_on_homing_pressed)
	if dash_button:
		dash_button.texture_normal = load("res://assets/icons/skils/PhantomDash.png")
		dash_button.pressed.connect(_on_dash_pressed)
	
	_update_all_visibility()
	
	if music_toggle:
		music_toggle.texture_normal = load("res://assets/icons/music.png")
		music_toggle.pressed.connect(_on_music_toggle)
		_update_music_button()
	if sfx_toggle:
		sfx_toggle.texture_normal = load("res://assets/icons/sound.png")
		sfx_toggle.pressed.connect(_on_sfx_toggle)
		_update_sfx_button()


func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_try_find_player()
	_update_cooldown_labels()


func _try_find_player() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var p := scene.find_child("Player", true, false)
	if p != null:
		_player = p
		if not p.shockwave_used.is_connected(_on_shockwave_used):
			p.shockwave_used.connect(_on_shockwave_used)
		if not p.goliath_charge_used.is_connected(_on_goliath_charge_used):
			p.goliath_charge_used.connect(_on_goliath_charge_used)
		if not p.homing_salvo_used.is_connected(_on_homing_salvo_used):
			p.homing_salvo_used.connect(_on_homing_salvo_used)
		if not p.dash_used.is_connected(_on_dash_used):
			p.dash_used.connect(_on_dash_used)
		_update_all_visibility()


func _update_all_visibility() -> void:
	if _player == null:
		_hide_all()
		return
	
	if shockwave_container:
		shockwave_container.visible = _player.has_shockwave_module
	
	if goliath_container:
		goliath_container.visible = _player.is_goliath
	
	if homing_container:
		homing_container.visible = _player.current_weapon_module == "rocket_homing"
	
	if dash_container:
		dash_container.visible = _player.current_ship == "phantom"


func _hide_all() -> void:
	if shockwave_container: shockwave_container.visible = false
	if goliath_container: goliath_container.visible = false
	if homing_container: homing_container.visible = false
	if dash_container: dash_container.visible = false


func _update_cooldown_labels() -> void:
	if _player == null:
		return
	
	_update_single_label(shockwave_label, shockwave_button, _player.shockwave_cooldown)
	_update_single_label(goliath_label, goliath_button, _player.goliath_charge_cooldown)
	_update_single_label(homing_label, homing_button, _player.homing_salvo_cooldown)
	_update_single_label(dash_label, dash_button, _player.dash_cooldown)


func _update_single_label(label: Label, button: TextureButton, cooldown: float) -> void:
	if label == null or button == null:
		return
	if not label.visible:
		return
	if cooldown <= 0.0:
		label.text = "Готово"
		label.modulate = Color(0.5, 1, 0.5, 1)
		button.modulate = Color(1, 1, 1, 1)
	else:
		label.text = "%.0fс" % cooldown
		label.modulate = Color(1, 0.6, 0.4, 1)
		button.modulate = Color(0.3, 0.3, 0.3, 0.5)


func _on_shockwave_pressed() -> void:
	if _player and _player.has_method("try_activate_shockwave"):
		_player.try_activate_shockwave()


func _on_goliath_pressed() -> void:
	if _player and _player.has_method("try_start_goliath_charge"):
		_player.try_start_goliath_charge()


func _on_homing_pressed() -> void:
	if _player and _player.has_method("try_activate_homing_salvo"):
		_player.try_activate_homing_salvo()


func _on_dash_pressed() -> void:
	if _player and _player.has_method("_do_dash"):
		_player._do_dash("up")


func _on_shockwave_used() -> void:
	if anim_shockwave:
		anim_shockwave.play("KDwave")


func _on_goliath_charge_used() -> void:
	if anim_goliath:
		anim_goliath.play("KDGoliathCharge")


func _on_homing_salvo_used() -> void:
	if anim_homing:
		anim_homing.play("KDHomingSalvo")


func _on_dash_used() -> void:
	if anim_dash:
		anim_dash.play("KDPhantomDash")


func _on_music_toggle() -> void:
	var am = get_node("/root/AudioManager")
	if am and am.has_method("toggle_music"):
		am.toggle_music()
		_update_music_button()


func _on_sfx_toggle() -> void:
	var am = get_node("/root/AudioManager")
	if am and am.has_method("toggle_sfx"):
		am.toggle_sfx()
		_update_sfx_button()


func _update_music_button() -> void:
	if not music_toggle:
		return
	var am = get_node("/root/AudioManager")
	if am:
		music_toggle.modulate = Color(1, 1, 1, 1) if am.music_volume > 0.0 else Color(0.3, 0.3, 0.3, 0.5)


func _update_sfx_button() -> void:
	if not sfx_toggle:
		return
	var am = get_node("/root/AudioManager")
	if am:
		sfx_toggle.modulate = Color(1, 1, 1, 1) if am.sfx_volume > 0.0 else Color(0.3, 0.3, 0.3, 0.5)


func update_score(value: int) -> void:
	score_label.text = "Очки: " + str(value)


func update_credits(value: int) -> void:
	credits_label.text = "Кредиты: " + str(value)


func update_lives(value: int) -> void:
	if lives_label != null:
		lives_label.text = "" + str(value)


func update_wave(value: int) -> void:
	wave_label.text = "Волна: " + str(value)
