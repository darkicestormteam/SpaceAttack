extends CharacterBody2D

signal player_died
signal health_changed(new_health: int)
signal shield_activated # визуальный/звуковой эффект при блокировке урона щитом
signal shield_recharged # когда щит снова готов

const SPEED: float = 400.0
const MARGIN: float = 20.0
const INVULN_DURATION: float = 1.0
const SHIELD_COOLDOWN: float = 10.0
const SHIELD_FLASH_DURATION: float = 0.2

var bullet_damage: int = 10
var shoot_delay: float = 0.2
var max_health: int = 3

# ID экипированного модуля оружия. "" — стандартная одиночная пуля,
# "shotgun" — веер из 3 пуль.
var current_weapon_module: String = ""

# Состояние модуля "Щит". Если has_shield_module = true, каждые 10 секунд
# щит готов блокировать один урон.
var has_shield_module: bool = false
var is_shield_ready: bool = true
var shield_timer: Timer

# Состояние модуля "Импульсная волна" (Shockwave) — активная способность с кулдауном.
var has_shockwave_module: bool = false
var shockwave_cooldown: float = 0.0
const SHOCKWAVE_COOLDOWN: float = 8.0
const SHOCKWAVE_SCENE: PackedScene = preload("res://entities/effects/Shockwave.tscn")
signal shockwave_used
signal shockwave_ready

@onready var muzzle: Marker2D = $Muzzle
@onready var sprite_2d: Sprite2D = $Sprite2D

var shoot_timer: float = 0.0
var health: int = 3
var invulnerable: bool = false
var blink_tween: Tween


func _ready() -> void:
	health_changed.emit(health)
	# Создаём таймер перезарядки щита программно (не нужно трогать .tscn)
	shield_timer = Timer.new()
	shield_timer.name = "ShieldTimer"
	shield_timer.wait_time = SHIELD_COOLDOWN
	shield_timer.one_shot = false
	shield_timer.autostart = false
	add_child(shield_timer)
	shield_timer.timeout.connect(_on_shield_ready)


func set_upgrades(damage_level: int, fire_rate_level: int, health_level: int) -> void:
	bullet_damage = 10 + damage_level * 5
	shoot_delay = max(0.05, 0.2 - fire_rate_level * 0.05)
	max_health = 3 + health_level
	health = max_health
	health_changed.emit(health)
	# После применения апгрейдов из магазина сразу подхватываем модули
	apply_module_effects()


# Загружает экипированные модули из SaveManager и применяет их эффекты.
func apply_module_effects() -> void:
	var sm := get_node_or_null("/root/SaveManager")
	if sm == null:
		current_weapon_module = ""
		has_shield_module = false
		return
	var equipped = sm.equipped_modules
	if equipped == null:
		current_weapon_module = ""
		has_shield_module = false
		return

	# Оружие
	var weapon_id = equipped.get("weapon", "")
	if weapon_id == null:
		weapon_id = ""
	current_weapon_module = str(weapon_id)

	# Защита
	var defense_id = equipped.get("defense", "")
	if defense_id == null:
		defense_id = ""
	has_shield_module = (str(defense_id) == "shield")

	# Утилита — Импульсная волна
	var utility_id = equipped.get("utility", "")
	if utility_id == null:
		utility_id = ""
	has_shockwave_module = (str(utility_id) == "shockwave")


func _process(_delta: float) -> void:
	shoot_timer += _delta
	if shoot_timer >= shoot_delay:
		shoot_timer = 0.0
		_shoot()

	# Перезарядка shockwave
	if shockwave_cooldown > 0.0:
		shockwave_cooldown = max(0.0, shockwave_cooldown - _delta)
		if shockwave_cooldown <= 0.0:
			shockwave_ready.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not has_shockwave_module:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		# Горячая клавиша F (или пробел — SPACE)
		if event.keycode == KEY_F or event.keycode == KEY_SPACE:
			try_activate_shockwave()


# Активирует Импульсную волну, если модуль экипирован и кулдаун закончился.
func try_activate_shockwave() -> bool:
	if not has_shockwave_module:
		return false
	if shockwave_cooldown > 0.0:
		return false
	if SHOCKWAVE_SCENE == null:
		return false

	var wave = SHOCKWAVE_SCENE.instantiate()
	var main = get_tree().current_scene
	main.add_child(wave)
	wave.global_position = global_position

	shockwave_cooldown = SHOCKWAVE_COOLDOWN
	shockwave_used.emit()
	return true


func _physics_process(_delta: float) -> void:
	var target_pos: Vector2 = get_global_mouse_position()

	var viewport_size = get_viewport_rect().size
	target_pos.x = clamp(target_pos.x, MARGIN, viewport_size.x - MARGIN)
	target_pos.y = clamp(target_pos.y, MARGIN, viewport_size.y - MARGIN)

	var direction = (target_pos - global_position).normalized()
	var distance = global_position.distance_to(target_pos)

	if distance > 2.0:
		velocity = direction * SPEED
	else:
		velocity = Vector2.ZERO

	move_and_slide()


func _shoot() -> void:
	var bullet_scene = preload("res://entities/projectiles/PlayerBullet.tscn")
	if not bullet_scene:
		return

	if current_weapon_module == "shotgun":
		# Дробовик: 3 пули веером (центр + ±30°)
		var directions: Array[Vector2] = [
			Vector2(0, -1),
			Vector2(-0.5, -1).normalized(),
			Vector2(0.5, -1).normalized()
		]
		for dir in directions:
			var bullet = bullet_scene.instantiate()
			bullet.global_position = muzzle.global_position
			bullet.damage = bullet_damage
			bullet.direction = dir
			get_tree().current_scene.add_child(bullet)
	else:
		# Стандартная одиночная пуля
		var bullet = bullet_scene.instantiate()
		bullet.global_position = muzzle.global_position
		bullet.damage = bullet_damage
		get_tree().current_scene.add_child(bullet)


func take_damage(amount: int) -> void:
	if invulnerable:
		return

	# Если модуль щита экипирован и щит готов — блокируем урон
	if has_shield_module and is_shield_ready:
		is_shield_ready = false
		shield_timer.start()
		_spawn_shield_flash()
		shield_activated.emit()
		return

	# Иначе — обычная логика получения урона
	self.health -= amount
	health_changed.emit(health)
	invulnerable = true
	_start_blinking()

	var main = get_tree().current_scene
	if main and main.has_method("shake_camera"):
		main.shake_camera(0.2, 5.0)

	if health <= 0:
		die()
		return

	await get_tree().create_timer(INVULN_DURATION).timeout
	invulnerable = false
	_stop_blinking()


# Вызывается таймером — щит снова готов блокировать урон
func _on_shield_ready() -> void:
	is_shield_ready = true
	shield_recharged.emit()


# Визуальный эффект: зелёный круг вокруг игрока на 0.2 сек
func _spawn_shield_flash() -> void:
	var flash := Node2D.new()
	flash.set_script(preload("res://entities/player/ShieldFlash.gd"))
	get_tree().current_scene.add_child(flash)
	flash.global_position = global_position
	flash.flash(SHIELD_FLASH_DURATION)


func die() -> void:
	player_died.emit()
	var main = get_tree().current_scene
	if main and main.has_method(&"game_over"):
		main.game_over()


func _start_blinking() -> void:
	if blink_tween:
		blink_tween.kill()
	blink_tween = create_tween()
	blink_tween.tween_property(sprite_2d, "modulate:a", 0.3, 0.1)
	blink_tween.tween_property(sprite_2d, "modulate:a", 1.0, 0.1)
	blink_tween.set_loops()


func _stop_blinking() -> void:
	sprite_2d.modulate.a = 1.0
	if blink_tween:
		blink_tween.kill()
		blink_tween = null
