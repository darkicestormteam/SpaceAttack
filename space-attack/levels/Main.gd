extends Node2D

## Единая машина состояний игры.
enum GamePhase {
	NORMAL,       # обычные волны (спавн мобов)
	BOSS_FIGHT,   # битва с боссом (волны 4,10)
	ASTEROID,     # астероидное поле (после первого босса)
	LASER_WALL,   # лазерная полоса (волна 9)
	GAME_OVER     # game over
}

signal score_changed(new_score: int)
signal credits_changed(new_credits: int)
signal lives_changed(new_lives: int)
signal wave_changed(new_wave: int)

@onready var scout_timer: Timer = $ScoutTimer
@onready var fighter_timer: Timer = $FighterTimer
@onready var camera: Camera2D = $Camera2D
@onready var parallax_bg: ParallaxBackground = $StarBackground if has_node("StarBackground") else null
@onready var bg_music: AudioStreamPlayer = $BGMusic
@onready var boss_music: AudioStreamPlayer = $BossMusic if has_node("BossMusic") else null
@onready var carrier_timer: Timer = $CarrierTimer if has_node("CarrierTimer") else null
@onready var start_ship: Node2D = $StartShip if has_node("StartShip") else null
@onready var marker_phantom_dash: Marker2D = $MarkerPhantomDash if has_node("MarkerPhantomDash") else null

@export var background_speed: float = 200.0  # скорость движения фона (вниз)

var sm: Node  # SaveManager reference

var score: int = 0
var wave_counter: int = 1
var enemies_killed_in_wave: int = 0
var enemies_to_next_wave: int = 10

# Количество кредитов, заработанных в этой игровой сессии (для кнопки x2)
var credits_earned_this_run: int = 0

# Единое состояние игры
var current_phase: int = GamePhase.NORMAL

# Босс
var boss_wave: int = 4
var mega_boss_wave: int = 10
var _boss_instance: Node = null

# Первый босс — механика ускорения фона
var first_boss_defeated: bool = false

# Флаг, что StartShip уже был активирован
var start_ship_activated: bool = false

# Флаг, что босс волны 10 уже заспавнен (предотвращает двойной спавн)
var boss_spawned_for_wave_10: bool = false

const MARGIN: float = 20.0

# === Лазерная полоса (волна 9) ===
const LASER_RUNNER_SCENE: PackedScene = preload("res://entities/obstacles/LaserObstacleRunner.tscn")
const LASER_WAVE_DURATION: float = 30.0

var laser_runner_instance: Node2D = null

# === Phantom Dash — двойной тап по экрану ===
const DOUBLE_TAP_WINDOW: float = 0.3
var _last_tap_time: float = 0.0
var _last_tap_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	sm = get_node("/root/SaveManager")
	sm.load_game()
	sm.reset_tmp_counters()
	sm.tmp_current_ship = sm.current_ship
	
	scout_timer.timeout.connect(_on_scout_timer_timeout)
	scout_timer.start()
	
	fighter_timer.timeout.connect(_on_fighter_timer_timeout)
	# FighterTimer starts after 10 sec
	get_tree().create_timer(10.0).timeout.connect(func(): fighter_timer.start())
	
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
			player.set_upgrades(sm.health_upgrade_level)

	# PauseMenu
	var pause_menu = $PauseMenu
	if pause_menu:
		pause_menu.hangar_requested.connect(_on_pause_hangar)
		pause_menu.restart_requested.connect(_on_pause_restart)

	# CarrierTimer — спавнит Carrier каждые 25 сек (запускается после победы над первым боссом)
	if carrier_timer == null:
		carrier_timer = Timer.new()
		carrier_timer.name = "CarrierTimer"
		carrier_timer.wait_time = 25.0
		carrier_timer.autostart = false
		add_child(carrier_timer)
	carrier_timer.timeout.connect(_on_carrier_timer_timeout)
	# Carrier не спавнится до победы над первым боссом

	# BossMusic в сцене имеет autoplay=true (особенность .tscn-создания),
	# но мы запускаем его только во время босса — останавливаем сразу.
	if boss_music:
		boss_music.stop()
		boss_music.finished.connect(_on_boss_music_finished)

	# Передаём скорость фона из инспектора в StarBackground
	if parallax_bg:
		parallax_bg.scroll_speed = Vector2(0, -background_speed)

	# Чанки скаутов — создаём и запускаем разовый таймер
	scout_cluster_timer = Timer.new()
	scout_cluster_timer.name = "ScoutClusterTimer"
	scout_cluster_timer.one_shot = true
	scout_cluster_timer.timeout.connect(_spawn_scout_cluster)
	add_child(scout_cluster_timer)
	scout_cluster_timer.wait_time = randf_range(SCOUT_CLUSTER_INTERVAL_MIN, SCOUT_CLUSTER_INTERVAL_MAX)
	scout_cluster_timer.start()

	# MegaBossV1 на волне 1 — для теста
	if wave_counter == mega_boss_wave:
		get_tree().create_timer(2.0).timeout.connect(func(): start_boss_fight(true))


func _process(_delta: float) -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	# Phantom Dash — двойной тап по экрану (мышь / тач)
	# Реагируем на все нажатия, включая double_click
	if event is InputEventMouseButton and event.pressed:
		var now := Time.get_ticks_msec() / 1000.0
		var elapsed := now - _last_tap_time
		_last_tap_time = now
		
		if elapsed > 0.0 and elapsed < DOUBLE_TAP_WINDOW:
			# Двойной тап — перемещаем MarkerPhantomDash и выполняем рывок
			var screen_pos: Vector2 = event.position
			if marker_phantom_dash and marker_phantom_dash.has_method("set_dash_target"):
				marker_phantom_dash.set_dash_target(screen_pos)
			
			# Выполняем рывок игрока к маркеру (150px в сторону маркера)
			var player = $Player
			if player and player.has_method("dash_to_target") and marker_phantom_dash:
				player.dash_to_target(marker_phantom_dash.global_position)


func _on_player_health_changed(new_health: int) -> void:
	lives_changed.emit(new_health)


func _on_player_died() -> void:
	game_over()


func game_over() -> void:
	if current_phase == GamePhase.GAME_OVER:
		return
	current_phase = GamePhase.GAME_OVER
	
	scout_timer.stop()
	fighter_timer.stop()
	if carrier_timer:
		carrier_timer.stop()
	if scout_cluster_timer:
		scout_cluster_timer.stop()
	if bg_music:
		bg_music.stop()
	if score > sm.high_score:
		sm.high_score = score
	sm.save_game()

	# Чистим лазеры
	_stop_laser_wave()

	# Ставим игру на паузу, чтобы на фоне не двигались враги/пули/фон.
	get_tree().paused = true

	var go_scene = preload("res://ui/screens/GameOver.tscn")
	if go_scene:
		var go_instance = go_scene.instantiate()
		add_child(go_instance)
		if go_instance.has_method("set_stats"):
			go_instance.set_stats(score, sm.credits, credits_earned_this_run)
	
	sm.on_game_over(score)
	
	# Отправляем счёт в лидерборд Yandex
	_submit_to_leaderboard()


## Воскрешает игрока после просмотра rewarded рекламы.
## Вызывается из GameOver.gd.
func revive_player() -> void:
	# Удаляем экран GameOver
	for child in get_children():
		if child is CanvasLayer and child.has_method("set_stats"):
			child.queue_free()
	
	# Снимаем паузу
	get_tree().paused = false
	
	# Воскрешаем игрока с 50% HP
	var player = $Player
	if player and player.has_method("revive_to_half"):
		player.revive_to_half()
		current_phase = GamePhase.NORMAL
		
		# Возобновляем спавн врагов
		scout_timer.start()
		if fighter_timer.is_stopped():
			fighter_timer.start()
		if carrier_timer and carrier_timer.is_stopped():
			carrier_timer.wait_time = 15.0
			carrier_timer.start()
		if scout_cluster_timer:
			scout_cluster_timer.wait_time = randf_range(SCOUT_CLUSTER_INTERVAL_MIN, SCOUT_CLUSTER_INTERVAL_MAX)
			scout_cluster_timer.start()
		
		print("[Main] Player revived with 50% HP!")


func add_score(amount: int) -> void:
	var mult := Constants.score_mult()
	score += int(ceil(float(amount) * mult))
	score_changed.emit(score)


func add_credits(amount: int) -> void:
	var mult := Constants.credits_mult()
	var earned = int(ceil(float(amount) * mult))
	sm.credits += earned
	credits_earned_this_run += earned
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


const MUSIC_FADE_DB: float = -80.0


func _crossfade_to(new_player: AudioStreamPlayer, duration: float = 1.0) -> void:
	var current: AudioStreamPlayer = null
	if bg_music and bg_music.playing:
		current = bg_music
	elif boss_music and boss_music.playing:
		current = boss_music

	var target_volume: float = new_player.volume_db if new_player else 0.0

	if new_player and new_player.stream:
		new_player.volume_db = MUSIC_FADE_DB
		new_player.play()
		var tw_in := create_tween()
		tw_in.tween_property(new_player, "volume_db", target_volume, duration)

	if current and current != new_player:
		var tw_out := create_tween()
		tw_out.tween_property(current, "volume_db", MUSIC_FADE_DB, duration)
		tw_out.tween_callback(Callable(current, "stop"))
		tw_out.tween_property(current, "volume_db", target_volume, 0.0)


func _on_enemy_killed() -> void:
	if current_phase != GamePhase.NORMAL:
		return
	enemies_killed_in_wave += 1
	sm.on_enemy_killed("", "")  # weapon_id и enemy_name передаём из сигнала врага
	if enemies_killed_in_wave >= enemies_to_next_wave:
		_advance_wave()


func _advance_wave() -> void:
	# Защита: не переходим на следующую волну, если не в NORMAL фазе
	if current_phase != GamePhase.NORMAL:
		return
	
	wave_counter += 1
	enemies_killed_in_wave = 0
	enemies_to_next_wave += 5
	
	# Волна 9 — StartShip уезжает, затем лазерная полоса
	if wave_counter == 9:
		if start_ship_activated and start_ship and start_ship.has_method("deactivate"):
			# Стартуем деактивацию StartShip (анимация ухода)
			start_ship.deactivate()
			start_ship_activated = false
		# Лазерная полоса — ждём пока все враги не умрут
		_request_laser_wave()
		return
	
	# Волна 10 — мега-босс (ждём пока все враги умрут)
	if wave_counter == mega_boss_wave:
		if boss_spawned_for_wave_10:
			return
		boss_spawned_for_wave_10 = true
		_request_event_after_enemies_cleared(_start_mega_boss_after_clear)
		return
	
	# Волна 4 — обычный босс
	if wave_counter == boss_wave:
		sm.on_wave_reached(wave_counter)
		start_boss_fight(false)
		return
	
	wave_changed.emit(wave_counter)
	sm.on_wave_reached(wave_counter)
	
	var new_scout_interval = max(0.5, scout_timer.wait_time - 0.1)
	scout_timer.wait_time = new_scout_interval
	
	if not fighter_timer.is_stopped():
		var new_fighter_interval = max(1.0, fighter_timer.wait_time - 0.2)
		fighter_timer.wait_time = new_fighter_interval


const BIG_ENEMY_FINAL_Y: float = 100.0
const BIG_ENEMY_START_Y: float = -150.0
const BIG_ENEMY_ENTRANCE_DURATION: float = 1.5


func _get_player() -> Node:
	return $Player if has_node("Player") else null


func _set_player_shooting(enabled: bool) -> void:
	var p = _get_player()
	if p:
		p.shooting_disabled = not enabled


func start_boss_fight(is_mega: bool = false) -> void:
	if current_phase != GamePhase.NORMAL:
		return
	current_phase = GamePhase.BOSS_FIGHT
	
	scout_timer.stop()
	fighter_timer.stop()
	if carrier_timer:
		carrier_timer.stop()
	if scout_cluster_timer:
		scout_cluster_timer.stop()
	
	# Деактивируем StartShip перед боссом
	if start_ship_activated and start_ship and start_ship.has_method("deactivate"):
		start_ship.deactivate()
		start_ship_activated = false

	if boss_music and boss_music.stream:
		_crossfade_to(boss_music, 1.0)

	var boss_scene: PackedScene
	if is_mega:
		boss_scene = preload("res://entities/enemies/mega_boss_v_1.tscn")
	else:
		boss_scene = preload("res://entities/enemies/Boss.tscn")
	if boss_scene:
		_boss_instance = boss_scene.instantiate()
		var vps = get_viewport_rect().size
		_boss_instance.global_position = Vector2(vps.x / 2.0, BIG_ENEMY_START_Y)
		call_deferred(&"add_child", _boss_instance)
		call_deferred(&"_animate_big_enemy_entrance", _boss_instance, BIG_ENEMY_FINAL_Y)
		call_deferred(&"shake_camera", 0.4, 12.0)

	wave_changed.emit(wave_counter)


func _animate_big_enemy_entrance(enemy: Node2D, final_y: float) -> void:
	if enemy == null:
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(enemy, "global_position:y", final_y, BIG_ENEMY_ENTRANCE_DURATION)


func _on_boss_music_finished() -> void:
	if boss_music:
		boss_music.play()


# --- Чанки скаутов ---

const SCOUT_SCENE: PackedScene = preload("res://entities/enemies/Scout.tscn")
const SCOUT_CLUSTER_INTERVAL_MIN: float = 12.0
const SCOUT_CLUSTER_INTERVAL_MAX: float = 18.0

var scout_cluster_timer: Timer


func _spawn_scout_cluster() -> void:
	var roll := randi() % 3
	match roll:
		0:
			var c := _spawn_scout_wall()
			print("[ScoutCluster] Стена: %d скаутов" % c)
		1:
			var c := _spawn_scout_v_wall()
			print("[ScoutCluster] V-стена: %d скаутов" % c)
		2:
			var c := _spawn_scout_dive_wall()
			print("[ScoutCluster] Пикировщики: %d скаутов" % c)
	if scout_cluster_timer:
		scout_cluster_timer.wait_time = randf_range(SCOUT_CLUSTER_INTERVAL_MIN, SCOUT_CLUSTER_INTERVAL_MAX)
		scout_cluster_timer.start()


const SPAWN_Y_OFFSCREEN: float = -200.0


func _spawn_scout_wall() -> int:
	if SCOUT_SCENE == null:
		return 0
	var count: int = 7
	var vps = get_viewport_rect().size
	var spacing: float = (vps.x - MARGIN * 2) / float(count - 1)
	for i in range(count):
		var scout = SCOUT_SCENE.instantiate()
		scout.behavior = 0
		scout.global_position = Vector2(MARGIN + i * spacing, SPAWN_Y_OFFSCREEN)
		add_child(scout)
	return count


func _spawn_scout_dive_wall() -> int:
	if SCOUT_SCENE == null:
		return 0
	var count: int = 5
	var vps = get_viewport_rect().size
	var from_left: bool = randi() % 2 == 0
	var start_x: float = MARGIN if from_left else vps.x - MARGIN
	var dir_x: float = 1.0 if from_left else -1.0
	for i in range(count):
		var scout = SCOUT_SCENE.instantiate()
		scout.behavior = 2
		scout.global_position = Vector2(start_x + i * 60.0 * dir_x, SPAWN_Y_OFFSCREEN + i * 50.0)
		add_child(scout)
	return count


func _spawn_scout_v_wall() -> int:
	if SCOUT_SCENE == null:
		return 0
	var count: int = 7
	var vps = get_viewport_rect().size
	var center_x: float = vps.x / 2.0
	for i in range(count):
		var scout = SCOUT_SCENE.instantiate()
		scout.behavior = 1
		var offset_x: float = (i - (count - 1) / 2.0) * 55.0
		var offset_y: float = abs(i - (count - 1) / 2.0) * 30.0
		scout.global_position = Vector2(center_x + offset_x, SPAWN_Y_OFFSCREEN + offset_y)
		add_child(scout)
	return count


# --- Астероиды (15-секундная фаза) ---

const ASTEROID_SCENE: PackedScene = preload("res://entities/asteroids/Asteroid.tscn")
const ASTEROID_SPAWN_INTERVAL: float = 0.5
const ASTEROID_CLUSTER_INTERVAL: float = 4.5
const ASTEROID_CLUSTER_COUNT: int = 5
const ASTEROID_CLUSTER_X_SPREAD: float = 60.0
const ASTEROID_CLUSTER_Y_SPREAD: float = 30.0

var asteroid_timer: Timer
var asteroid_cluster_timer: Timer


func _setup_asteroid_timers() -> void:
	if asteroid_timer == null:
		asteroid_timer = Timer.new()
		asteroid_timer.name = "AsteroidTimer"
		asteroid_timer.wait_time = ASTEROID_SPAWN_INTERVAL
		asteroid_timer.one_shot = false
		add_child(asteroid_timer)
	if asteroid_timer.timeout.is_connected(_spawn_asteroid_single):
		asteroid_timer.timeout.disconnect(_spawn_asteroid_single)
	asteroid_timer.timeout.connect(_spawn_asteroid_single)

	if asteroid_cluster_timer == null:
		asteroid_cluster_timer = Timer.new()
		asteroid_cluster_timer.name = "AsteroidClusterTimer"
		asteroid_cluster_timer.wait_time = ASTEROID_CLUSTER_INTERVAL
		asteroid_cluster_timer.one_shot = false
		add_child(asteroid_cluster_timer)
	if asteroid_cluster_timer.timeout.is_connected(_spawn_asteroid_cluster):
		asteroid_cluster_timer.timeout.disconnect(_spawn_asteroid_cluster)
	asteroid_cluster_timer.timeout.connect(_spawn_asteroid_cluster)


func _spawn_asteroid_single() -> void:
	if ASTEROID_SCENE == null:
		return
	var asteroid = ASTEROID_SCENE.instantiate()
	var vps = get_viewport_rect().size
	asteroid.global_position = Vector2(randf_range(MARGIN, vps.x - MARGIN), -60.0)
	add_child(asteroid)


func _spawn_asteroid_cluster() -> void:
	if ASTEROID_SCENE == null:
		return
	var vps = get_viewport_rect().size
	var center_x: float = randf_range(MARGIN + 60, vps.x - MARGIN - 60)
	var center_y: float = -60.0
	for i in ASTEROID_CLUSTER_COUNT:
		var asteroid = ASTEROID_SCENE.instantiate()
		asteroid.global_position = Vector2(
			center_x + randf_range(-ASTEROID_CLUSTER_X_SPREAD, ASTEROID_CLUSTER_X_SPREAD),
			center_y + i * ASTEROID_CLUSTER_Y_SPREAD / float(ASTEROID_CLUSTER_COUNT)
		)
		add_child(asteroid)


func _start_asteroid_spawning() -> void:
	current_phase = GamePhase.ASTEROID
	_setup_asteroid_timers()
	asteroid_timer.start()
	asteroid_cluster_timer.start()


func _stop_asteroid_spawning() -> void:
	if asteroid_timer:
		asteroid_timer.stop()
	if asteroid_cluster_timer:
		asteroid_cluster_timer.stop()


# --- Механика после первого босса ---

const BG_SPEED_UP_DURATION: float = 2.0
const BG_FAST_SPEED: float = 800.0
const BG_FAST_HOLD_DURATION: float = 15.0
const BG_SPEED_DOWN_DURATION: float = 2.0


# Экран победы при убийстве мегабосса на волне 10
func _game_won() -> void:
	current_phase = GamePhase.GAME_OVER
	
	# Останавливаем всё
	scout_timer.stop()
	fighter_timer.stop()
	if carrier_timer:
		carrier_timer.stop()
	if scout_cluster_timer:
		scout_cluster_timer.stop()
	if bg_music:
		bg_music.stop()
	if boss_music:
		boss_music.stop()
	
	# Сохраняем рекорд
	if score > sm.high_score:
		sm.high_score = score
	sm.on_game_over(score)
	
	# Ачивка: победа в игре (для триумвирата и непобедимого)
	sm.on_game_won()
	
	# Отправляем счёт в лидерборд Yandex
	_submit_to_leaderboard()
	
	# Ждём 2 секунды, чтобы игрок увидел взрыв босса
	await get_tree().create_timer(2.0).timeout
	
	# Показываем экран победы
	get_tree().paused = true
	
	var victory_scene = preload("res://ui/screens/VictoryScreen.tscn")
	if victory_scene:
		var vi_instance = victory_scene.instantiate()
		add_child(vi_instance)
		if vi_instance.has_method("set_stats"):
			vi_instance.set_stats(score, sm.credits, credits_earned_this_run)


func end_boss_fight() -> void:
	if current_phase != GamePhase.BOSS_FIGHT:
		return
	if _boss_instance != null and not is_instance_valid(_boss_instance):
		_boss_instance = null

	# Уведомляем SaveManager об убийстве босса (для ачивок)
	sm.on_enemy_killed("", "", true)

	if bg_music and bg_music.stream:
		_crossfade_to(bg_music, 1.0)

	wave_counter += 1
	enemies_killed_in_wave = 0
	enemies_to_next_wave += 5
	wave_changed.emit(wave_counter)

	# Проверка: это был мегабосс на волне 10? — экран победы
	if wave_counter > mega_boss_wave and boss_spawned_for_wave_10:
		_game_won()
		return

	if not first_boss_defeated:
		first_boss_defeated = true
		_set_player_shooting(false)
		_start_first_boss_speedup()
	else:
		current_phase = GamePhase.NORMAL
		if parallax_bg:
			parallax_bg.scroll_speed = Vector2(0, -background_speed)
		# Прямое возобновление спавна, т.к. фаза уже NORMAL
		_stop_asteroid_spawning()
		_set_player_shooting(true)
		scout_timer.start()
		if scout_cluster_timer:
			scout_cluster_timer.wait_time = randf_range(SCOUT_CLUSTER_INTERVAL_MIN, SCOUT_CLUSTER_INTERVAL_MAX)
			scout_cluster_timer.start()
		if fighter_timer.is_stopped():
			fighter_timer.start()
		if carrier_timer and carrier_timer.is_stopped():
			carrier_timer.start()
		if not start_ship_activated and wave_counter == 5 and start_ship and start_ship.has_method("activate"):
			start_ship_activated = true
			start_ship.activate()


func _start_first_boss_speedup() -> void:
	if parallax_bg:
		var tw_speed_up := create_tween()
		tw_speed_up.tween_method(_set_bg_speed_value, background_speed, BG_FAST_SPEED, BG_SPEED_UP_DURATION)
		tw_speed_up.tween_callback(_on_speed_up_done)


func _set_bg_speed_value(value: float) -> void:
	if parallax_bg:
		parallax_bg.scroll_speed = Vector2(0, -value)
	background_speed = value


func _on_speed_up_done() -> void:
	_start_asteroid_spawning()
	sm.tmp_asteroid_phase = true
	var ast_duration: float = Constants.get_value("asteroid_phase_duration", 15.0)
	get_tree().create_timer(ast_duration).timeout.connect(_on_fast_hold_end)


func _on_fast_hold_end() -> void:
	if parallax_bg:
		var tw_speed_down := create_tween()
		tw_speed_down.tween_method(_set_bg_speed_value, BG_FAST_SPEED, 200.0, BG_SPEED_DOWN_DURATION)
		tw_speed_down.tween_callback(_resume_spawning)


func _resume_spawning() -> void:
	# Защита: возобновляем спавн только если мы в фазе ASTEROID или LASER_WALL
	if current_phase != GamePhase.ASTEROID and current_phase != GamePhase.LASER_WALL:
		return
	current_phase = GamePhase.NORMAL
	
	_stop_asteroid_spawning()
	_set_player_shooting(true)
	scout_timer.start()
	if scout_cluster_timer:
		scout_cluster_timer.wait_time = randf_range(SCOUT_CLUSTER_INTERVAL_MIN, SCOUT_CLUSTER_INTERVAL_MAX)
		scout_cluster_timer.start()
	if fighter_timer.is_stopped():
		fighter_timer.start()
	if carrier_timer and carrier_timer.is_stopped():
		carrier_timer.start()
	if not start_ship_activated and wave_counter == 5 and start_ship and start_ship.has_method("activate"):
		start_ship_activated = true
		start_ship.activate()


func _on_scout_timer_timeout() -> void:
	var scene = preload("res://entities/enemies/Scout.tscn")
	if not scene:
		return
	var roll := randf() * 100.0
	var scout_behavior: int
	if roll < 40.0:
		scout_behavior = 0
	elif roll < 70.0:
		scout_behavior = 1
	elif roll < 90.0:
		scout_behavior = 2
	else:
		scout_behavior = 3
	var enemy = scene.instantiate()
	enemy.behavior = scout_behavior
	var vps = get_viewport_rect().size
	var rx := randf_range(MARGIN, vps.x - MARGIN)
	enemy.global_position = Vector2(rx, -50)
	add_child(enemy)


func _on_fighter_timer_timeout() -> void:
	var scene = preload("res://entities/enemies/Fighter.tscn")
	if scene:
		_spawn_enemy(scene)


const CARRIER_RESPAWN_DELAY: float = 35.0


func _on_carrier_timer_timeout() -> void:
	for child in get_children():
		if child is Node and child.is_in_group("enemy") and "Carrier" in child.name:
			return
	var scene = preload("res://entities/enemies/Carrier.tscn")
	if not scene:
		return
	var carrier = scene.instantiate()
	var vps = get_viewport_rect().size
	carrier.global_position = Vector2(vps.x / 2.0, BIG_ENEMY_START_Y)
	add_child(carrier)
	_animate_big_enemy_entrance(carrier, BIG_ENEMY_FINAL_Y)
	shake_camera(0.4, 10.0)
	carrier.tree_exited.connect(_on_carrier_died)


func _on_carrier_died() -> void:
	if carrier_timer == null:
		return
	carrier_timer.stop()
	carrier_timer.wait_time = CARRIER_RESPAWN_DELAY
	carrier_timer.start()


func _spawn_enemy(scene: PackedScene) -> void:
	var enemy = scene.instantiate()
	var vps = get_viewport_rect().size
	var rx = randf_range(MARGIN, vps.x - MARGIN)
	enemy.global_position = Vector2(rx, -50)
	add_child(enemy)


# === Универсальное ожидание очистки врагов ===

## Callback, который будет вызван когда все враги умрут.
var _pending_event_callback: Callable = Callable()
## Флаг что мы ожидаем очистки.
var _pending_event_active: bool = false


## Останавливает спавн и ждёт пока все живые враги умрут,
## затем вызывает callback.
func _request_event_after_enemies_cleared(callback: Callable) -> void:
	if _pending_event_active:
		return
	_pending_event_active = true
	_pending_event_callback = callback
	
	# Останавливаем спавн прямо сейчас
	scout_timer.stop()
	fighter_timer.stop()
	if carrier_timer:
		carrier_timer.stop()
	if scout_cluster_timer:
		scout_cluster_timer.stop()
	
	print("[Event] Ожидание уничтожения врагов...")
	_check_enemies_before_event()


func _check_enemies_before_event() -> void:
	if not _pending_event_active:
		return
	
	# Проверяем, есть ли живые враги в сцене
	var has_enemies: bool = false
	for child in get_children():
		if child.is_in_group("enemy") and not child.is_queued_for_deletion():
			has_enemies = true
			break
	
	if has_enemies:
		# Есть враги — проверяем снова через 1 секунду
		get_tree().create_timer(1.0).timeout.connect(_check_enemies_before_event)
		return
	
	# Врагов нет — выполняем отложенный callback
	_pending_event_active = false
	var cb = _pending_event_callback
	_pending_event_callback = Callable()
	cb.call()


# === Мега-босс (волна 10) — отложенный запуск после очистки врагов ===

func _start_mega_boss_after_clear() -> void:
	if boss_spawned_for_wave_10:
		start_boss_fight(true)


# === Лазерная полоса препятствий (волна 9) ===

func _request_laser_wave() -> void:
	_request_event_after_enemies_cleared(start_laser_wave)


func start_laser_wave() -> void:
	if current_phase != GamePhase.NORMAL:
		return
	current_phase = GamePhase.LASER_WALL
	
	# Останавливаем спавн врагов
	scout_timer.stop()
	fighter_timer.stop()
	if carrier_timer:
		carrier_timer.stop()
	if scout_cluster_timer:
		scout_cluster_timer.stop()
	
	# Отключаем стрельбу игрока
	_set_player_shooting(false)
	
	wave_changed.emit(wave_counter)
	
	# Ускорение фона (как в астероидной фазе)
	if parallax_bg:
		var tw_speed_up := create_tween()
		tw_speed_up.tween_method(_set_bg_speed_value, background_speed, BG_FAST_SPEED, BG_SPEED_UP_DURATION)
		tw_speed_up.tween_callback(_on_laser_speed_up_done)
	
	print("[LaserWave] Волна 9: ускорение фона + лазерная полоса на 30 секунд")


func _on_laser_speed_up_done() -> void:
	if current_phase != GamePhase.LASER_WALL:
		return
	
	# Спавним раннер только после ускорения фона
	if LASER_RUNNER_SCENE:
		laser_runner_instance = LASER_RUNNER_SCENE.instantiate()
		laser_runner_instance.position = Vector2(0, -150.0)
		add_child(laser_runner_instance)
	
	# Через 30 секунд завершаем лазерную фазу
	var laser_duration: float = Constants.get_value("laser_wave_duration", 30.0)
	get_tree().create_timer(laser_duration).timeout.connect(_stop_laser_wave)


func _stop_laser_wave() -> void:
	if current_phase != GamePhase.LASER_WALL:
		return
	
	# 1. Останавливаем спавн новых генераторов
	if laser_runner_instance and is_instance_valid(laser_runner_instance):
		laser_runner_instance.stop_spawning()
	
	print("[LaserWave] Спавн остановлен, ждём 5 секунд пока генераторы улетят")
	
	# 2. Ждём 5 секунд и чистим всё
	get_tree().create_timer(5.0).timeout.connect(_finish_laser_wave)


func _finish_laser_wave() -> void:
	if current_phase != GamePhase.LASER_WALL:
		return
	
	# Удаляем раннер
	if laser_runner_instance and is_instance_valid(laser_runner_instance):
		laser_runner_instance.queue_free()
		laser_runner_instance = null
	
	# Удаляем оставшиеся генераторы
	for child in get_children():
		if child.is_in_group("laser_wall_generator"):
			child.queue_free()
	
	# Ачивка: пройдена лазерная полоса (волна 9)
	sm.on_laser_wall_completed()
	
	# Включаем стрельбу игрока
	_set_player_shooting(true)
	
	# Замедление фона (как в астероидной фазе)
	if parallax_bg:
		var tw_speed_down := create_tween()
		tw_speed_down.tween_method(_set_bg_speed_value, BG_FAST_SPEED, 200.0, BG_SPEED_DOWN_DURATION)
		tw_speed_down.tween_callback(_on_laser_slow_down_done)
	
	print("[LaserWave] Лазерная полоса завершена, замедление фона")


func _on_laser_slow_down_done() -> void:
	# _resume_spawning() сам установит current_phase = NORMAL
	_resume_spawning()
	background_speed = 200.0


# --- PauseMenu handlers ---

func _on_pause_hangar() -> void:
	# Проверяем ачивки, связанные с прогрессом (волны, счёт, корабли), перед выходом
	if current_phase != GamePhase.GAME_OVER:
		_on_game_over_checks()
	get_tree().paused = false
	await _show_ad_and_go_hangar()


func _on_pause_restart() -> void:
	# Проверяем ачивки, связанные с прогрессом (волны, счёт, корабли), перед рестартом
	if current_phase != GamePhase.GAME_OVER:
		_on_game_over_checks()
	get_tree().paused = false
	get_tree().reload_current_scene()


# Вызывается при выходе из игры (смерть, рестарт, выход в ангар) для проверки ачивок
func _on_game_over_checks() -> void:
	sm.on_game_over(score)


# Запустить очередь рекламы (interstitial), затем перейти в Hangar
func _show_ad_and_go_hangar() -> void:
	var ads = get_node_or_null("/root/AdsManager") as Node
	if ads == null or not ads.has_method("queue_interstitial"):
		get_tree().change_scene_to_file("res://ui/screens/Hangar.tscn")
		return
	
	ads.queue_interstitial()
	
	# Ждём завершения очереди
	await ads.queue_completed
	
	get_tree().change_scene_to_file("res://ui/screens/Hangar.tscn")


# Отправить финальный счёт в лидерборд Yandex Games "BestScore"
func _submit_to_leaderboard() -> void:
	var ads = get_node_or_null("/root/AdsManager") as Node
	if ads == null or not ads.has_method("leaderboard_set_score"):
		return
	if not ads.is_leaderboard_ready:
		push_warning("[Main] Leaderboard not ready, skipping score submission")
		return
	ads.leaderboard_set_score("bestscore", score, "")