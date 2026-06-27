extends CharacterBody2D

const SPEED: float = 50.0
const AMPLITUDE: float = 100.0
const MAX_HEALTH: int = 400
const SHOOT_INTERVAL: float = 2.0
const SUMMON_INTERVAL: float = 6.0
const ScoutScript = preload("res://entities/enemies/Scout.gd")

var health: int = MAX_HEALTH
var is_being_rammed: bool = false
var _start_x: float
var _time: float = 0.0
var _dying: bool = false

@onready var hitbox: Area2D = $Hitbox
@onready var muzzle: Marker2D = $Muzzle
@onready var animation_player: AnimationPlayer = $AnimationPlayer
var _player_in_hitbox: Node = null
var _contact_damage_timer: Timer = null
var _shoot_timer_base: float = SHOOT_INTERVAL
var _summon_timer_base: float = SUMMON_INTERVAL
const CONTACT_DAMAGE_INTERVAL: float = 0.2

# === Настройки визуальной индикации урона (редактируются в Инспекторе) ===
@export_group("Damage Flash")
## Цвет яркой вспышки (значения > 1 дают эффект «пересвета»).
@export var flash_color_bright: Color = Color(3, 3, 3, 1)
## Цвет тинта урона (обычно красноватый).
@export var flash_color_damage: Color = Color(1.5, 0.3, 0.3, 1)
## Длительность одной фазы мерцания (сек).
@export_range(0.01, 0.5, 0.01) var flash_step_duration: float = 0.05
## Сколько раз повторить вспышку bright→damage.
@export_range(1, 10, 1) var flash_cycles: int = 2


func _ready() -> void:
	add_to_group("enemy")
	_start_x = global_position.x
	queue_redraw()

	# Множители от сложности
	var enemy_hp_mul: float = Constants.enemy_hp_mult()
	var boss_hp_mul: float = Constants.boss_hp_mult()
	var cd_red: float = Constants.boss_cooldown_reduction()
	health = int(ceil(float(MAX_HEALTH) * enemy_hp_mul * boss_hp_mul))
	_shoot_timer_base = SHOOT_INTERVAL
	_summon_timer_base = SUMMON_INTERVAL
	
	var shoot_interval := _shoot_timer_base * (1.0 - cd_red)
	var summon_interval := _summon_timer_base * (1.0 - cd_red)

	# Таймер стрельбы
	var shoot_timer := Timer.new()
	shoot_timer.name = "ShootTimer"
	shoot_timer.wait_time = shoot_interval
	shoot_timer.autostart = true
	shoot_timer.timeout.connect(_shoot)
	add_child(shoot_timer)

	# Таймер призыва скаутов
	var summon_timer := Timer.new()
	summon_timer.name = "SummonTimer"
	summon_timer.wait_time = summon_interval
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
	# При смерти не рисуем фолбэк-квадраты — пусть видна только анимация взрыва
	if _dying:
		return
	draw_rect(Rect2(-32, -32, 64, 64), Color(0.6, 0, 0, 1))
	draw_rect(Rect2(-30, -30, 60, 60), Color(0.8, 0.1, 0.1, 1), false, 2.0)


func _process(delta: float) -> void:
	_time += delta
	# Синусоидальное движение влево-вправо
	global_position.x = _start_x + sin(_time * SPEED * 0.05) * AMPLITUDE


func take_damage(amount: int) -> void:
	# Визуальная индикация получения урона — мерцание
	_flash_damage()

	health -= amount
	if health <= 0:
		die()


func _flash_damage() -> void:
	# Быстрое мерцание: bright → damage повторяется flash_cycles раз, затем возврат к нормали.
	# Цвета и длительность настраиваются в Инспекторе (см. @export_group выше).
	var tw := create_tween()
	for i in range(flash_cycles):
		tw.tween_property(self, "modulate", flash_color_bright, flash_step_duration)
		tw.tween_property(self, "modulate", flash_color_damage, flash_step_duration)
	# Финальный возврат к нормальному цвету
	tw.tween_property(self, "modulate", Color.WHITE, flash_step_duration)


func die() -> void:
	# Если уже в процессе смерти — игнорируем повторные вызовы
	if is_queued_for_deletion() or _dying:
		return

	var main = get_tree().current_scene
	if main and main.has_method("end_boss_fight"):
		main.end_boss_fight()
	if main and main.has_method("add_score"):
		main.add_score(500)
	if main and main.has_method("add_credits"):
		main.add_credits(200)
	_dying = true
	# Принудительно перерисовываем ноду, чтобы _draw() прекратил рисовать фолбэк-квадраты
	queue_redraw()

	# Останавливаем движение и стрельбу
	set_physics_process(false)
	set_process(false)
	# Отключаем хитбокс
	if hitbox:
		hitbox.set_deferred("monitoring", false)
		hitbox.set_deferred("monitorable", false)
	# Останавливаем таймеры
	for child in get_children():
		if child is Timer and child.name in ["ShootTimer", "SummonTimer", "ContactDamageTimer"]:
			child.stop()

	# Запускаем анимацию смерти
	if animation_player and animation_player.has_animation("die"):
		print("[Boss] Playing die animation")
		# Подключаем сигнал окончания анимации (one-shot)
		if not animation_player.animation_finished.is_connected(_on_die_animation_finished):
			animation_player.animation_finished.connect(_on_die_animation_finished)
		animation_player.play("die")
		# Fallback: если сигнал по какой-то причине не сработает,
		# удаляем босса через длительность анимации + запас
		var anim_length: float = animation_player.current_animation_length
		if anim_length <= 0.0:
			anim_length = 1.5
		get_tree().create_timer(anim_length + 0.2).timeout.connect(_finish_die)
	else:
		print("[Boss] Die animation not found, instant death")
		queue_free()


func _on_die_animation_finished(anim_name: StringName) -> void:
	if anim_name != &"die":
		return
	print("[Boss] Die animation finished")
	if animation_player and animation_player.animation_finished.is_connected(_on_die_animation_finished):
		animation_player.animation_finished.disconnect(_on_die_animation_finished)
	_finish_die()


func _finish_die() -> void:
	if is_queued_for_deletion():
		return
	queue_free()


func _spawn_death_particles() -> void:
	pass


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
	# Снаряды спавнятся в позиции маркера Muzzle, привязанного к боссу
	var spawn_pos := muzzle.global_position if muzzle else global_position
	for dir in directions:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = spawn_pos
		bullet.direction = dir
		get_tree().current_scene.add_child(bullet)


func _summon_adds() -> void:
	if is_queued_for_deletion():
		return
	var scout_scene = preload("res://entities/enemies/Scout.tscn")
	if not scout_scene:
		return
	# 2 призванных камикадзе в позиции босса (пониженная награда — 10%)
	for i in range(2):
		var scout = scout_scene.instantiate()
		scout.behavior = ScoutScript.Behavior.SUMMONED_KAMIKAZE
		scout.global_position = global_position + Vector2((i - 0.5) * 60.0, 40.0)
		get_tree().current_scene.add_child(scout)
