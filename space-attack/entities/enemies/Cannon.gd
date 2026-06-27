extends Area2D
class_name Cannon

## Турель на обшивке корабля. Поворачивается к игроку, стреляет сдвоенным лазером.

const HEALTH_PACK_DROP_CHANCE: float = 0.02
const HEALTH_PACK_SCENE: PackedScene = preload("res://entities/items/HealthPack.tscn")

@export var health: int = 60
@export var max_health: int = 60
@export var shoot_cooldown: float = 5.0      # КД между залпами (сек)
@export var dual_shot_delay: float = 0.2     # задержка между двумя лазерами (сек)
@export var turn_speed: float = 2.0          # скорость поворота к игроку (рад/сек)
@export var laser_scene: PackedScene         # сцена лазера

@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var die_anim: AnimatedSprite2D = $die
@onready var muzzle: Marker2D = $Marker2D
@onready var die_sound: AudioStreamPlayer2D = $Die
@onready var laser_sound: AudioStreamPlayer2D = $LaserSound

# === Настройки визуальной индикации урона ===
@export_group("Damage Flash")
@export var flash_color_bright: Color = Color(3, 3, 3, 1)
@export var flash_color_damage: Color = Color(1.5, 0.3, 0.3, 1)
@export_range(0.01, 0.5, 0.01) var flash_step_duration: float = 0.05
@export_range(1, 10, 1) var flash_cycles: int = 2

var _can_shoot: bool = true
var _dying: bool = false
var _player: Node2D = null

## Флаг активности — когда false, турель не двигается и не стреляет.
var _active: bool = true


func _ready() -> void:
	add_to_group("enemy")
	add_to_group("enemy_turret")
	
	# Ищем игрока
	_player = get_tree().current_scene.get_node_or_null("Player")
	
	# Таймер КД стрельбы
	var cooldown_timer := Timer.new()
	cooldown_timer.name = "CooldownTimer"
	cooldown_timer.wait_time = shoot_cooldown
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_on_cooldown_end)
	add_child(cooldown_timer)
	
	# Первый выстрел через 1.5 секунды после появления
	get_tree().create_timer(1.5).timeout.connect(_try_shoot)


## Включить/выключить турель.
## При выключении скрываем, отключаем физику и стрельбу.
## При включении показываем, включаем физику и запускаем первый выстрел.
func set_active(flag: bool) -> void:
	if _dying:
		return
	if flag == _active:
		return
	
	_active = flag
	
	if _active:
		# Включаем
		visible = true
		$CollisionShape2D.set_deferred("disabled", false)
		_can_shoot = true
		# Первый выстрел через 1.5 сек после активации
		get_tree().create_timer(1.5).timeout.connect(_try_shoot)
	else:
		# Выключаем — скрываем, отключаем коллизию, сбрасываем КД
		visible = false
		$CollisionShape2D.set_deferred("disabled", true)
		_can_shoot = false
		var ct: Timer = $CooldownTimer
		if ct:
			ct.stop()


func _process(delta: float) -> void:
	if _dying or not _active:
		return
	
	# Поворот к игроку
	if _player and is_instance_valid(_player):
		var dir_to_player: Vector2 = (_player.global_position - global_position).normalized()
		# Маркер (дуло) при rotation=0 смотрит вниз (Vector2.DOWN = (0,1)).
		# dir_to_player.angle() возвращает угол от оси X.
		# Для направления вниз angle() = PI/2, но нам нужен rotation = 0,
		# поэтому вычитаем PI/2.
		var target_angle: float = dir_to_player.angle() - PI / 2.0
		var current_angle: float = global_rotation
		var diff: float = _angle_diff(current_angle, target_angle)
		
		if absf(diff) > 0.01:
			var step: float = turn_speed * delta
			global_rotation += clampf(diff, -step, step)


func _angle_diff(from: float, to: float) -> float:
	var diff: float = fmod(to - from, TAU)
	if diff > PI:
		diff -= TAU
	elif diff < -PI:
		diff += TAU
	return diff


func _try_shoot() -> void:
	if _dying or not _can_shoot:
		return
	if not is_instance_valid(_player):
		return
	
	_can_shoot = false
	_shoot_dual()


func _shoot_dual() -> void:
	if _dying:
		return
	
	# Анимация выстрела
	sprite.play("default")
	
	# Первый лазер
	_spawn_laser()
	
	# Второй лазер через dual_shot_delay
	get_tree().create_timer(dual_shot_delay).timeout.connect(_spawn_laser)
	
	# Звук выстрела
	if laser_sound:
		laser_sound.play()
	
	# Запуск КД
	var cooldown_timer = $CooldownTimer
	if cooldown_timer:
		cooldown_timer.start()


func _spawn_laser() -> void:
	if _dying or not laser_scene or not muzzle:
		return
	
	var laser = laser_scene.instantiate()
	laser.global_position = muzzle.global_position
	laser.global_rotation = global_rotation
	get_tree().current_scene.add_child(laser)


func _on_cooldown_end() -> void:
	_can_shoot = true
	_try_shoot()


func take_damage(amount: int) -> void:
	if _dying:
		return
	_flash_damage()
	health -= amount
	if health <= 0:
		_die()


func _flash_damage() -> void:
	var tw := create_tween()
	for i in range(flash_cycles):
		tw.tween_property(sprite, "modulate", flash_color_bright, flash_step_duration)
		tw.tween_property(sprite, "modulate", flash_color_damage, flash_step_duration)
	tw.tween_property(sprite, "modulate", Color.WHITE, flash_step_duration)


func _try_drop_health_pack() -> void:
	if not (randf() < HEALTH_PACK_DROP_CHANCE and HEALTH_PACK_SCENE):
		return
	var pack = HEALTH_PACK_SCENE.instantiate()
	pack.position = global_position
	get_tree().current_scene.call_deferred("add_child", pack)


func _die() -> void:
	if _dying:
		return
	_try_drop_health_pack()
	_dying = true
	
	# Отключаем коллизию
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Звук смерти
	if die_sound:
		die_sound.play()
	
	# Анимация смерти (взрыв)
	sprite.visible = false
	die_anim.visible = true
	die_anim.play("die")
	
	# Удаляемся после окончания анимации
	await die_anim.animation_finished
	queue_free()