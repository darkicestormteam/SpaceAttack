extends CharacterBody2D

const SPEED: float = 50.0
const AMPLITUDE: float = 100.0
const MAX_HEALTH: int = 300
const SHOOT_INTERVAL: float = 2.0
const SUMMON_INTERVAL: float = 6.0

var health: int = MAX_HEALTH
var is_being_rammed: bool = false
var _start_x: float
var _time: float = 0.0

@onready var hitbox: Area2D = $Hitbox
var _player_in_hitbox: Node = null
var _contact_damage_timer: Timer = null
const CONTACT_DAMAGE_INTERVAL: float = 2.0


func _ready() -> void:
	add_to_group("enemy")
	_start_x = global_position.x
	queue_redraw()

	# Таймер стрельбы
	var shoot_timer := Timer.new()
	shoot_timer.name = "ShootTimer"
	shoot_timer.wait_time = SHOOT_INTERVAL
	shoot_timer.autostart = true
	shoot_timer.timeout.connect(_shoot)
	add_child(shoot_timer)

	# Таймер призыва скаутов
	var summon_timer := Timer.new()
	summon_timer.name = "SummonTimer"
	summon_timer.wait_time = SUMMON_INTERVAL
	summon_timer.autostart = true
	summon_timer.timeout.connect(_summon_adds)
	add_child(summon_timer)

	# Таймер периодического урона при контакте с игроком (каждые 2 секунды)
	_contact_damage_timer = Timer.new()
	_contact_damage_timer.name = "ContactDamageTimer"
	_contact_damage_timer.wait_time = CONTACT_DAMAGE_INTERVAL
	_contact_damage_timer.one_shot = false
	_contact_damage_timer.autostart = false
	add_child(_contact_damage_timer)
	_contact_damage_timer.timeout.connect(_on_contact_damage_timer)

	# Обработчик столкновений с игроком через Area2D Hitbox
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)
		hitbox.body_exited.connect(_on_hitbox_body_exited)


func _on_hitbox_body_exited(body: Node) -> void:
	# Игрок покинул зону — останавливаем периодический урон
	if body == _player_in_hitbox:
		_player_in_hitbox = null
		if _contact_damage_timer:
			_contact_damage_timer.stop()


func _on_contact_damage_timer() -> void:
	# Периодический урон каждые 2 секунды пока игрок в зоне и враг жив
	if is_queued_for_deletion():
		if _contact_damage_timer:
			_contact_damage_timer.stop()
		return
	if not is_instance_valid(_player_in_hitbox):
		_player_in_hitbox = null
		if _contact_damage_timer:
			_contact_damage_timer.stop()
		return
	if not (_player_in_hitbox is CharacterBody2D):
		return
	if not _player_in_hitbox.is_in_group("player"):
		return
	if is_being_rammed:
		return
	# Симметричный обмен каждые 2 секунды пока игрок в зоне
	if _player_in_hitbox.has_method("take_damage"):
		_player_in_hitbox.take_damage(1)
	if is_queued_for_deletion():
		if _contact_damage_timer:
			_contact_damage_timer.stop()
		return
	take_damage(30)
	if is_queued_for_deletion():
		if _contact_damage_timer:
			_contact_damage_timer.stop()


func _on_hitbox_body_entered(body: Node) -> void:
	if is_being_rammed or is_queued_for_deletion():
		return
	if body == self or not (body is CharacterBody2D):
		return
	if not body.is_in_group("player"):
		return
	# Симметричный обмен: игрок получает 1 урон при физическом столкновении, противник получает 30 урона
	if body.has_method("take_damage"):
		body.take_damage(1)
	if is_queued_for_deletion():
		return
	take_damage(30)
	# Если враг выжил — запускаем периодический урон каждые 2 секунды
	if not is_queued_for_deletion():
		_player_in_hitbox = body
		if _contact_damage_timer and _contact_damage_timer.is_stopped():
			_contact_damage_timer.start()


func _draw() -> void:
	draw_rect(Rect2(-32, -32, 64, 64), Color(0.6, 0, 0, 1))
	draw_rect(Rect2(-30, -30, 60, 60), Color(0.8, 0.1, 0.1, 1), false, 2.0)


func _process(delta: float) -> void:
	_time += delta
	# Синусоидальное движение влево-вправо
	global_position.x = _start_x + sin(_time * SPEED * 0.05) * AMPLITUDE


func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		die()


func die() -> void:
	var main = get_tree().current_scene
	if main and main.has_method("add_score"):
		main.add_score(500)
	if main and main.has_method("add_credits"):
		main.add_credits(200)
	if main and main.has_method("end_boss_fight"):
		main.end_boss_fight()

	_spawn_death_particles()
	queue_free()


func _spawn_death_particles() -> void:
	var particles := CPUParticles2D.new()
	particles.amount = 20
	particles.lifetime = 0.8
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.color = Color.DARK_RED
	particles.global_position = global_position
	particles.emitting = true
	get_tree().current_scene.add_child(particles)
	get_tree().create_timer(1.5).timeout.connect(particles.queue_free)

	var c := Node2D.new()
	c.global_position = global_position
	c.set_process(false)
	c.draw.connect(func():
		c.draw_circle(Vector2.ZERO, 32.0, Color.DARK_RED)
	)
	get_tree().current_scene.add_child(c)
	c.queue_redraw()
	get_tree().create_timer(0.5).timeout.connect(c.queue_free)


func _shoot() -> void:
	if is_queued_for_deletion():
		return
	var bullet_scene = preload("res://entities/projectiles/EnemyBullet.tscn")
	if not bullet_scene:
		return
	# Веер из 5 пуль: вниз, вниз-влево, вниз-вправо, влево, вправо
	var directions: Array[Vector2] = [
		Vector2(0, 1),
		Vector2(-0.5, 1).normalized(),
		Vector2(0.5, 1).normalized(),
		Vector2(-1, 0),
		Vector2(1, 0)
	]
	for dir in directions:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = global_position
		bullet.direction = dir
		get_tree().current_scene.add_child(bullet)


func _summon_adds() -> void:
	if is_queued_for_deletion():
		return
	var scout_scene = preload("res://entities/enemies/Scout.tscn")
	if not scout_scene:
		return
	# 2 скаута в позиции босса
	for i in range(2):
		var scout = scout_scene.instantiate()
		scout.global_position = global_position + Vector2((i - 0.5) * 60.0, 40.0)
		get_tree().current_scene.add_child(scout)
