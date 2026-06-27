extends CharacterBody2D

# Загружаем скрипт Scout, чтобы получить доступ к enum Behavior
const ScoutScript = preload("res://entities/enemies/Scout.gd")

# === Настройки врага Carrier ===
const MAX_HEALTH: int = 400
const DRIFT_SPEED: float = 20.0
const DRIFT_AMPLITUDE: float = 100.0
const SCOUT_SPAWN_INTERVAL: float = 3.0
const SCOUT_SPAWN_COUNT: int = 2
const REWARD_CREDITS: int = 100

# === Настройки тарана ===
const LIFETIME_ON_SCREEN: float = 25.0     # сколько секунд Carrier висит на экране
const RAM_BACKUP_DURATION: float = 0.25    # длительность отката назад
const RAM_BACKUP_DISTANCE: float = 60.0    # на сколько пикселей откатывается
const RAM_SPEED: float = 400.0             # скорость тарана вниз (постоянная)
const RAM_DAMAGE_TO_PLAYER: int = 1        # урон игроку при таране

# === Damage flash настройки ===
@export_group("Damage Flash")
@export var flash_color_bright: Color = Color(3, 3, 3, 1)
@export var flash_color_damage: Color = Color(1.5, 0.3, 0.3, 1)
@export_range(0.01, 0.5, 0.01) var flash_step_duration: float = 0.05
@export_range(1, 10, 1) var flash_cycles: int = 2

var health: int = MAX_HEALTH
var _time: float = 0.0
var _start_x: float
var _is_dying: bool = false

# Состояния Carrier
enum CarrierState { DRIFTING, BACKING_UP, RAMMING }
var _state: int = CarrierState.DRIFTING
var _backup_tween: Tween = null

@onready var base_collision: CollisionPolygon2D = $Base
@onready var right_collision: CollisionPolygon2D = $Right
@onready var left_collision: CollisionPolygon2D = $Left
@onready var base_hitbox: Area2D = $BaseHitbox
@onready var right_hitbox: Area2D = $RightHitbox
@onready var left_hitbox: Area2D = $LeftHitbox
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var spawn_marker_left: Marker2D = $Marker2D2
@onready var spawn_marker_right: Marker2D = $Marker2D
@onready var sprite: Node2D = $AnimatedSprite2D

var _scout_timer: Timer = null
var _lifetime_timer: Timer = null
var _player_in_hitbox: Node = null
var _contact_damage_timer: Timer = null
const CONTACT_DAMAGE_INTERVAL: float = 0.5


func _ready() -> void:
	add_to_group("enemy")
	add_to_group("carrier_body")
	_start_x = global_position.x
	
	# Множитель здоровья от сложности
	var hp_mult := Constants.enemy_hp_mult()
	if hp_mult != 1.0:
		health = int(ceil(float(health) * hp_mult))

	# Отключаем физические коллизии — Carrier не должен отталкивать врагов
	collision_mask = 0

	# CollisionPolygon2D на CharacterBody2D теперь только визуальные (броня выключена)
	right_collision.disabled = true
	left_collision.disabled = true
	base_collision.disabled = false  # Base оставляем как барьер для пуль

	# Группы для Area2D хитбоксов
	base_hitbox.add_to_group("carrier_base")
	right_hitbox.add_to_group("carrier_armor")
	left_hitbox.add_to_group("carrier_armor")

	base_hitbox.body_entered.connect(_on_hitbox_body_entered)
	base_hitbox.body_exited.connect(_on_hitbox_body_exited)

	# Таймер периодического урона при контакте с игроком (каждые 2 секунды)
	_contact_damage_timer = Timer.new()
	_contact_damage_timer.name = "ContactDamageTimer"
	_contact_damage_timer.wait_time = CONTACT_DAMAGE_INTERVAL
	_contact_damage_timer.one_shot = false
	_contact_damage_timer.autostart = false
	add_child(_contact_damage_timer)
	_contact_damage_timer.timeout.connect(_on_contact_damage_timer)

	# Таймер спавна скаутов
	_scout_timer = Timer.new()
	_scout_timer.name = "ScoutSpawnTimer"
	_scout_timer.wait_time = SCOUT_SPAWN_INTERVAL
	_scout_timer.autostart = true
	add_child(_scout_timer)
	_scout_timer.timeout.connect(_on_scout_spawn_timer)

	# Таймер времени жизни на экране — 25 секунд, затем таран
	_lifetime_timer = Timer.new()
	_lifetime_timer.name = "LifetimeTimer"
	_lifetime_timer.wait_time = LIFETIME_ON_SCREEN
	_lifetime_timer.one_shot = true
	_lifetime_timer.autostart = true
	add_child(_lifetime_timer)
	_lifetime_timer.timeout.connect(_start_ram_sequence)


func _physics_process(delta: float) -> void:
	if _is_dying or is_queued_for_deletion():
		return
	
	match _state:
		CarrierState.DRIFTING:
			_process_drifting(delta)
		CarrierState.BACKING_UP:
			# Во время отката назад движение управляется Tween
			pass
		CarrierState.RAMMING:
			_process_ramming(delta)


func _process_drifting(delta: float) -> void:
	_time += delta
	var offset := sin(_time * 0.8) * DRIFT_AMPLITUDE
	velocity.x = cos(_time * 0.8) * DRIFT_SPEED * offset * 0.01
	velocity.y = 0.0
	move_and_slide()


func _process_ramming(delta: float) -> void:
	# Движение вниз с постоянной скоростью
	velocity = Vector2(0, RAM_SPEED)
	move_and_slide()
	
	# Проверка выхода за нижнюю границу экрана — сразу queue_free
	var viewport_size = get_viewport_rect().size
	if global_position.y > viewport_size.y + 100:
		if not _is_dying and not is_queued_for_deletion():
			queue_free()


func _start_ram_sequence() -> void:
	if _state != CarrierState.DRIFTING or _is_dying or is_queued_for_deletion():
		return
	
	_state = CarrierState.BACKING_UP
	
	# Останавливаем спавн скаутов
	if _scout_timer:
		_scout_timer.stop()
	
	# Анимация отката назад (по Y вверх)
	var target_y = global_position.y - RAM_BACKUP_DISTANCE
	_backup_tween = create_tween()
	_backup_tween.set_trans(Tween.TRANS_BACK)
	_backup_tween.set_ease(Tween.EASE_OUT)
	_backup_tween.tween_property(self, "global_position:y", target_y, RAM_BACKUP_DURATION)
	_backup_tween.tween_callback(_start_ram)


func _start_ram() -> void:
	if _is_dying or is_queued_for_deletion():
		return
	_state = CarrierState.RAMMING
	
	# Визуальная вспышка при старте тарана
	var tw_visual := create_tween()
	tw_visual.tween_property(self, "modulate", Color(3, 3, 3, 1), 0.05)
	tw_visual.tween_property(self, "modulate", Color.WHITE, 0.1)
	
	# Включаем коллизию только с игроком (слой 3 = бит 2 = 4)
	# чтобы Carrier не сталкивался с другими врагами во время полёта
	collision_mask = 4


func _on_hitbox_body_entered(body: Node) -> void:
	if _is_dying or is_queued_for_deletion():
		return
	if body == self or not (body is CharacterBody2D):
		return
	if not body.is_in_group("player"):
		return
	
	if _state == CarrierState.RAMMING:
		# При таране наносим усиленный урон
		if body.has_method("take_damage"):
			body.take_damage(RAM_DAMAGE_TO_PLAYER)
		return
	
	# Наносим урон игроку
	if body.has_method("take_damage"):
		body.take_damage(1)
	if is_queued_for_deletion():
		return
	# Если выжил — запускаем периодический урон
	_player_in_hitbox = body
	if _contact_damage_timer and _contact_damage_timer.is_stopped():
		_contact_damage_timer.start()


func _on_hitbox_body_exited(body: Node) -> void:
	if body == _player_in_hitbox:
		_player_in_hitbox = null
		if _contact_damage_timer:
			_contact_damage_timer.stop()


func _on_contact_damage_timer() -> void:
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
	if _player_in_hitbox.has_method("take_damage"):
		_player_in_hitbox.take_damage(1)


func take_damage(amount: int) -> void:
	if _is_dying:
		return
	health -= amount
	_flash_damage()
	if health <= 0:
		_die()


func _flash_damage() -> void:
	var tw := create_tween()
	for i in range(flash_cycles):
		tw.tween_property(self, "modulate", flash_color_bright, flash_step_duration)
		tw.tween_property(self, "modulate", flash_color_damage, flash_step_duration)
	tw.tween_property(self, "modulate", Color.WHITE, flash_step_duration)


func _die() -> void:
	if _is_dying:
		return
	_is_dying = true

	set_physics_process(false)
	set_process(false)
	if _scout_timer:
		_scout_timer.stop()
	if _lifetime_timer:
		_lifetime_timer.stop()
	if _backup_tween and _backup_tween.is_valid():
		_backup_tween.kill()
	
	base_hitbox.set_deferred("monitoring", false)
	right_hitbox.set_deferred("monitoring", false)
	left_hitbox.set_deferred("monitoring", false)
	# Отключаем коллизии через set_deferred — нельзя менять состояние
	# CollisionPolygon2D во время обработки коллизий (flushing queries).
	base_collision.set_deferred("disabled", true)
	right_collision.set_deferred("disabled", true)
	left_collision.set_deferred("disabled", true)

	var main = get_tree().current_scene
	if main and main.has_method("add_credits"):
		main.add_credits(REWARD_CREDITS)
	if main and main.has_method("_on_enemy_killed"):
		main._on_enemy_killed()

	if anim_player and anim_player.has_animation("die"):
		anim_player.play("die")
		await anim_player.animation_finished
	queue_free()


func _on_scout_spawn_timer() -> void:
	if _is_dying or is_queued_for_deletion() or _state != CarrierState.DRIFTING:
		return
	_spawn_kamikaze_scout(spawn_marker_left)
	_spawn_kamikaze_scout(spawn_marker_right)


func _spawn_kamikaze_scout(marker: Marker2D) -> void:
	var scout_scene = preload("res://entities/enemies/Scout.tscn")
	if not scout_scene or not marker:
		return
	var scout = scout_scene.instantiate()
	# Используем загруженный скрипт для доступа к enum
	# Призванные камикадзе (SUMMONED_KAMIKAZE) дают 10% награды
	scout.behavior = ScoutScript.Behavior.SUMMONED_KAMIKAZE
	scout.global_position = marker.global_position
	get_tree().current_scene.add_child(scout)
