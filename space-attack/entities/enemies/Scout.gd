extends CharacterBody2D

enum Behavior { KAMIKAZE, SINE_WAVE, DIVE_BOMBER, FLANKER }

@export var behavior: Behavior = Behavior.KAMIKAZE

const BASE_SPEED: float = 150.0
const REWARD_CREDITS: int = 5
const REWARD_SCORE: int = 10

var health: int = 15
var _base_health: int = 15
var _time: float = 0.0
var _start_x: float
var _state_timer: float = 0.0
var _state: int = 0  # для многофазных поведений
var _has_fired: bool = false
var _bullet_scene: PackedScene = null

# Параметры поведений (настраиваются в _setup_behavior)
var _speed: float = BASE_SPEED
var _sine_amplitude: float = 50.0
var _sine_freq: float = 2.0
var _dive_fire_count: int = 0

# Kamikaze — плавное наведение
var _kamikaze_velocity: Vector2 = Vector2(0, 300)
var _kamikaze_turn_speed: float = 120.0  # градусов в секунду
var _kamikaze_phase: int = 0  # 0 = наведение, 1 = полёт по касательной
var _kamikaze_coast_velocity: Vector2 = Vector2.ZERO

# Флаг для Goliath тарана
var is_being_rammed: bool = false


func _ready() -> void:
	add_to_group("enemy")
	_start_x = global_position.x
	_bullet_scene = preload("res://entities/projectiles/EnemyBullet.tscn")
	_setup_behavior()
	var hitbox := get_node_or_null("Hitbox")
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)


func _on_hitbox_body_entered(body: Node) -> void:
	if is_being_rammed or is_queued_for_deletion():
		return
	if body == self or not (body is CharacterBody2D):
		return
	if not body.is_in_group("player"):
		return
	# Симметричный обмен: игрок получает 1 урон, враг умирает
	if body.has_method("take_damage"):
		body.take_damage(1)
	_die()


func _setup_behavior() -> void:
	match behavior:
		Behavior.KAMIKAZE:
			_speed = 300.0
			health = 20
			_base_health = 20
			_kamikaze_velocity = Vector2(0, 300)
		Behavior.SINE_WAVE:
			_speed = 120.0
			_sine_amplitude = 50.0
			_sine_freq = 2.0
		Behavior.DIVE_BOMBER:
			_speed = 0.0
			_state = 0  # зависание
			_state_timer = 1.0
			_dive_fire_count = 0
		Behavior.FLANKER:
			_speed = 180.0


func _physics_process(delta: float) -> void:
	if is_queued_for_deletion():
		return
	_time += delta
	var viewport_size = get_viewport_rect().size

	match behavior:
		Behavior.KAMIKAZE:
			_process_kamikaze(delta, viewport_size)
		Behavior.SINE_WAVE:
			_process_sine_wave(delta, viewport_size)
		Behavior.DIVE_BOMBER:
			_process_dive_bomber(delta, viewport_size)
		Behavior.FLANKER:
			_process_flanker(delta, viewport_size)

	# Удаление при выходе за границы
	if global_position.y > viewport_size.y + 80 or global_position.y < -200:
		queue_free()
	if global_position.x < -100 or global_position.x > viewport_size.x + 100:
		queue_free()
	# Контактный урон с игроком обрабатывается через Area2D Hitbox -> _on_hitbox_body_entered


# --- KAMIKAZE (плавное наведение + паника после пролёта) ---

func _process_kamikaze(delta: float, _viewport_size: Vector2) -> void:
	var player = get_tree().current_scene.get_node_or_null("Player")
	if not player:
		return
	
	if _kamikaze_phase == 0:
		# Фаза наведения
		var distance_to_player = global_position.distance_to(player.global_position)
		
		# Если расстояние >= 50 пикселей, плавно поворачиваем к игроку
		if distance_to_player >= 1:
			var desired_dir = (player.global_position - global_position).normalized()
			var current_dir = _kamikaze_velocity.normalized()
			var angle_diff = current_dir.angle_to(desired_dir)
			var max_angle = deg_to_rad(_kamikaze_turn_speed) * delta
			var new_angle = clamp(angle_diff, -max_angle, max_angle)
			var new_dir = current_dir.rotated(new_angle)
			_kamikaze_velocity = new_dir * 300.0
		# Если расстояние < 50 пикселей — летим по последнему вычисленному вектору (не обновляем направление)
		global_position += _kamikaze_velocity * delta
		
		# Проверка пролёта мимо игрока по вертикали
		if global_position.y > player.global_position.y + 30:
			# Паника! Уходим по случайной диагонали вниз-вбок
			_kamikaze_phase = 1
			var exit_dir = Vector2(randf_range(-0.6, 0.6), 1.0).normalized()
			_kamikaze_velocity = exit_dir * randf_range(250.0, 300.0)
			modulate = Color.ORANGE  # визуальный эффект паники
	else:
		# Фаза паники: летим по случайной диагонали, больше не наводимся
		global_position += _kamikaze_velocity * delta
	
	# Столкновение с игроком для KAMIKAZE обрабатывается через Area2D Hitbox -> _on_hitbox_body_entered


# --- SINE_WAVE ---
func _process_sine_wave(delta: float, viewport_size: Vector2) -> void:
	global_position.y += _speed * delta
	global_position.x = _start_x + sin(_time * _sine_freq) * _sine_amplitude
	# Стрельба при достижении середины экрана
	if not _has_fired and global_position.y >= viewport_size.y * 0.4:
		_has_fired = true
		_fire_at_player()


# --- DIVE_BOMBER ---
func _process_dive_bomber(delta: float, viewport_size: Vector2) -> void:
	match _state:
		0:  # Зависание сверху
			_state_timer -= delta
			# Мигание красным
			modulate = Color(1, 0.3 + sin(_time * 12) * 0.5, 0.3)
			if _state_timer <= 0.0:
				_state = 1
				_speed = 400.0
				modulate = Color.WHITE
				_dive_fire_count = 0
				# 3 выстрела с задержкой 0.5 секунд
				_fire_at_player()
				get_tree().create_timer(0.5).timeout.connect(_dive_bomber_fire)
				get_tree().create_timer(1.0).timeout.connect(_dive_bomber_fire)
		1:  # Рывок вниз по диагонали
			var dive_dir = Vector2(-0.5, 1).normalized() if _start_x > viewport_size.x / 2 else Vector2(0.5, 1).normalized()
			global_position += dive_dir * _speed * delta


func _dive_bomber_fire() -> void:
	if not is_queued_for_deletion():
		_dive_fire_count += 1
		if _dive_fire_count <= 2:
			_fire_at_player()


# --- FLANKER ---
func _process_flanker(delta: float, viewport_size: Vector2) -> void:
	match _state:
		0:  # Дуга вверх
			global_position.y += _speed * 0.3 * delta
			global_position.x += _speed * 0.8 * delta * (1 if _start_x < viewport_size.x / 2 else -1)
			if _time > 1.0:
				_state = 1
		1:  # Дуга вниз + стрельба
			global_position.y += _speed * delta
			global_position.x += _speed * 0.5 * delta * (-1 if _start_x < viewport_size.x / 2 else 1)
			if not _has_fired:
				_has_fired = true
				_fire_at_player()
				get_tree().create_timer(0.3).timeout.connect(_fire_at_player)


func _fire_at_player() -> void:
	if _bullet_scene == null or is_queued_for_deletion():
		return
	var player = get_tree().current_scene.get_node_or_null("Player")
	if not player:
		return
	var bullet = _bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.direction = (player.global_position - global_position).normalized()
	get_tree().current_scene.add_child(bullet)


func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		_die()


func _die() -> void:
	if is_queued_for_deletion():
		return
	var main = get_tree().current_scene
	if main and main.has_method("add_score"):
		main.add_score(REWARD_SCORE)
	if main and main.has_method("add_credits"):
		main.add_credits(REWARD_CREDITS)
	if main and main.has_method("_on_enemy_killed"):
		main._on_enemy_killed()
	_spawn_death_particles()
	_spawn_death_circle()
	queue_free()


func _spawn_death_particles() -> void:
	var particles = CPUParticles2D.new()
	particles.amount = 8
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.color = Color.RED
	particles.global_position = global_position
	particles.emitting = true
	get_tree().current_scene.add_child(particles)
	get_tree().create_timer(1.0).timeout.connect(particles.queue_free)


func _spawn_death_circle() -> void:
	var c := Node2D.new()
	c.global_position = global_position
	c.set_process(false)
	c.draw.connect(func():
		c.draw_circle(Vector2.ZERO, 16.0, Color.RED)
	)
	get_tree().current_scene.add_child(c)
	c.queue_redraw()
	get_tree().create_timer(0.3).timeout.connect(c.queue_free)
