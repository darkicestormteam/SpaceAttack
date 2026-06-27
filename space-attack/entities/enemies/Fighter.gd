extends CharacterBody2D

const SPEED: float = 100.0
const HEALTH_PACK_DROP_CHANCE: float = 0.02
const HEALTH_PACK_SCENE: PackedScene = preload("res://entities/items/HealthPack.tscn")

# Лёгкое покачивание по X
const SINE_AMPLITUDE: float = 30.0
const SINE_FREQ: float = 1.5

var _time: float = 0.0
var _start_x: float

var health: int = 40
var is_being_rammed: bool = false

@onready var shoot_timer: Timer = $ShootTimer
@onready var sprite: Sprite2D = $Sprite2D
@onready var muzzle: Marker2D = $Muzzle
@onready var hitbox: Area2D = $Hitbox
@onready var anim_player: AnimationPlayer = $AnimationPlayer

var _player_in_hitbox: Node = null
var _contact_damage_timer: Timer = null
const CONTACT_DAMAGE_INTERVAL: float = 0.5

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
	
	# Множитель здоровья от сложности
	var hp_mult := Constants.enemy_hp_mult()
	if hp_mult != 1.0:
		health = int(ceil(float(health) * hp_mult))
	
	shoot_timer.timeout.connect(_shoot)
	shoot_timer.start()
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	hitbox.body_exited.connect(_on_hitbox_body_exited)

	# Таймер периодического урона при контакте с игроком (каждые 2 секунды)
	_contact_damage_timer = Timer.new()
	_contact_damage_timer.name = "ContactDamageTimer"
	_contact_damage_timer.wait_time = CONTACT_DAMAGE_INTERVAL
	_contact_damage_timer.one_shot = false
	_contact_damage_timer.autostart = false
	add_child(_contact_damage_timer)
	_contact_damage_timer.timeout.connect(_on_contact_damage_timer)


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
	if is_being_rammed:
		return
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


func _process(delta: float) -> void:
	_time += delta
	global_position.y += SPEED * delta
	# Лёгкое покачивание по X
	global_position.x = _start_x + sin(_time * SINE_FREQ) * SINE_AMPLITUDE

	var viewport_size = get_viewport_rect().size
	if global_position.y > viewport_size.y + 50:
		queue_free()


func _on_hitbox_body_entered(body: Node) -> void:
	if is_being_rammed or is_queued_for_deletion():
		return
	if body == self or not (body is CharacterBody2D):
		return
	if not body.is_in_group("player"):
		return
	# Симметричный обмен: игрок получает 1 урон, враг получает 30 урона
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


func _shoot() -> void:
	var player = get_tree().current_scene.get_node_or_null("Player")
	if not player or is_queued_for_deletion():
		return
	
	var bullet_scene = load("res://entities/projectiles/EnemyBullet.tscn")
	if bullet_scene:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = muzzle.global_position
		var dir = (player.global_position - global_position).normalized()
		# Ограничиваем угол стрельбы: только вниз (180°)
		# Если Y-компонент направления отрицательный (стрельба вверх) —
		# разрешаем стрелять только в нижнюю полуокружность
		if dir.y < 0.0:
			dir.y = -dir.y
		bullet.use_blue = true
		bullet.direction = dir
		get_tree().current_scene.add_child(bullet)


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


func _try_drop_health_pack() -> void:
	if not (randf() < HEALTH_PACK_DROP_CHANCE and HEALTH_PACK_SCENE):
		return
	var pack = HEALTH_PACK_SCENE.instantiate()
	pack.position = global_position
	get_tree().current_scene.call_deferred("add_child", pack)


func die() -> void:
	_try_drop_health_pack()
	
	var main = get_tree().current_scene
	if main and main.has_method("add_score"):
		main.add_score(20)
	if main and main.has_method("add_credits"):
		main.add_credits(10)
	if main and main.has_method("_on_enemy_killed"):
		main._on_enemy_killed()
	set_physics_process(false)
	set_process(false)
	var hitbox := get_node_or_null("Hitbox")
	if hitbox:
		hitbox.set_deferred("monitoring", false)
	if anim_player and anim_player.has_animation("die"):
		anim_player.play("die")
		await anim_player.animation_finished
	queue_free()
