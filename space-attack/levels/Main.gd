extends Node2D

signal score_changed(new_score: int)
signal credits_changed(new_credits: int)
signal lives_changed(new_lives: int)
signal wave_changed(new_wave: int)

@onready var scout_timer: Timer = $ScoutTimer
@onready var fighter_timer: Timer = $FighterTimer
@onready var kamikaze_timer: Timer = $KamikazeTimer
@onready var camera: Camera2D = $Camera2D

var sm: Node  # SaveManager reference

var score: int = 0
var wave_counter: int = 1
var enemies_killed_in_wave: int = 0
var enemies_to_next_wave: int = 10

const MARGIN: float = 20.0


func _ready() -> void:
	sm = get_node("/root/SaveManager")
	sm.load_game()
	
	scout_timer.timeout.connect(_on_scout_timer_timeout)
	scout_timer.start()
	
	fighter_timer.timeout.connect(_on_fighter_timer_timeout)
	# FighterTimer starts after 10 sec
	get_tree().create_timer(10.0).timeout.connect(func(): fighter_timer.start())
	
	kamikaze_timer.timeout.connect(_on_kamikaze_timer_timeout)
	
	var hud = $BattleHUD
	if hud:
		score_changed.connect(hud.update_score)
		credits_changed.connect(hud.update_credits)
		lives_changed.connect(hud.update_lives)
		wave_changed.connect(hud.update_wave)
		wave_changed.emit(wave_counter)
	
	var player = $Player
	if player:
		player.player_died.connect(_on_player_died)
		player.health_changed.connect(_on_player_health_changed)
		if player.has_method("set_upgrades"):
			player.set_upgrades(
				sm.damage_upgrade_level,
				sm.fire_rate_upgrade_level,
				sm.health_upgrade_level
			)


func _on_player_health_changed(new_health: int) -> void:
	lives_changed.emit(new_health)


func _on_player_died() -> void:
	game_over()


func game_over() -> void:
	scout_timer.stop()
	fighter_timer.stop()
	kamikaze_timer.stop()
	
	if score > sm.high_score:
		sm.high_score = score
	sm.save_game()
	
	var go_scene = preload("res://ui/screens/GameOver.tscn")
	if go_scene:
		var go_instance = go_scene.instantiate()
		add_child(go_instance)
		if go_instance.has_method("set_stats"):
			go_instance.set_stats(score, sm.credits)


func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)


func add_credits(amount: int) -> void:
	sm.credits += amount
	sm.save_game()
	credits_changed.emit(sm.credits)


func shake_camera(duration: float, intensity: float) -> void:
	if not camera:
		return
	var orig_offset = camera.offset
	var tw = create_tween()
	for i in range(10):
		var rx = randf_range(-intensity, intensity)
		var ry = randf_range(-intensity, intensity)
		tw.tween_property(camera, "offset", Vector2(rx, ry), duration / 10.0)
	tw.tween_property(camera, "offset", orig_offset, duration / 10.0)


func _on_enemy_killed() -> void:
	enemies_killed_in_wave += 1
	
	if enemies_killed_in_wave >= enemies_to_next_wave:
		_advance_wave()


func _advance_wave() -> void:
	wave_counter += 1
	enemies_killed_in_wave = 0
	enemies_to_next_wave += 5
	
	wave_changed.emit(wave_counter)
	
	var new_scout_interval = max(0.5, scout_timer.wait_time - 0.1)
	scout_timer.wait_time = new_scout_interval
	
	if not fighter_timer.is_stopped():
		var new_fighter_interval = max(1.0, fighter_timer.wait_time - 0.2)
		fighter_timer.wait_time = new_fighter_interval
	
	# Запуск KamikazeTimer при wave >= 2 (если ещё не запущен)
	if wave_counter >= 2 and kamikaze_timer.is_stopped():
		kamikaze_timer.start()
	elif not kamikaze_timer.is_stopped():
		var new_kamikaze_interval = max(2.0, kamikaze_timer.wait_time - 0.3)
		kamikaze_timer.wait_time = new_kamikaze_interval


func _on_scout_timer_timeout() -> void:
	var scene = preload("res://entities/enemies/Scout.tscn")
	if scene:
		_spawn_enemy(scene)


func _on_fighter_timer_timeout() -> void:
	var scene = preload("res://entities/enemies/Fighter.tscn")
	if scene:
		_spawn_enemy(scene)


func _on_kamikaze_timer_timeout() -> void:
	var scene = preload("res://entities/enemies/Kamikaze.tscn")
	if scene:
		_spawn_enemy(scene)


func _spawn_enemy(scene: PackedScene) -> void:
	var enemy = scene.instantiate()
	var vps = get_viewport_rect().size
	var rx = randf_range(MARGIN, vps.x - MARGIN)
	enemy.global_position = Vector2(rx, -50)
	add_child(enemy)
