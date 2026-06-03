extends CharacterBody2D

signal player_died
signal health_changed(new_health: int)
signal shield_activated
signal shield_recharged

const SPEED: float = 400.0
const MARGIN: float = 20.0
const INVULN_DURATION: float = 1.5
const SHIELD_COOLDOWN: float = 10.0
const SHIELD_FLASH_DURATION: float = 0.2

# Phantom — dash
const DASH_COOLDOWN_TIME: float = 3.0
const DASH_DISTANCE: float = 150.0
const DOUBLE_TAP_WINDOW: float = 0.3
const DASH_INVULN_DURATION: float = 0.2

# Goliath
const GOLIATH_SPEED_MULTIPLIER: float = 0.7

var bullet_damage: int = 10
var shoot_delay: float = 0.2
var max_health: int = 3

var current_weapon_module: String = ""
var current_ship: String = "vanguard"
var is_goliath: bool = false

# Phantom dash
var last_input_time: Dictionary = {"left": 0.0, "right": 0.0, "up": 0.0, "down": 0.0}
var dash_cooldown: float = 0.0

# Defense — старый shield
var has_shield_module: bool = false
var is_shield_ready: bool = true
var shield_timer: Timer

# Defense — energy_shield
var has_energy_shield: bool = false
var energy_shield_durability: int = 0
const ENERGY_SHIELD_MAX_DURABILITY: int = 50
const ENERGY_SHIELD_RECHARGE_TIME: float = 20.0
var energy_shield_recharge_timer: Timer
var energy_shield_visual: Node2D = null

# Defense — reactive_armor
var has_reactive_armor: bool = false
const REACTIVE_ARMOR_RADIUS: float = 200.0
const REACTIVE_ARMOR_DAMAGE: int = 10

# Utility — Turbo
var turbo_active: bool = false
const TURBO_SPEED_MULTIPLIER: float = 1.3

# Utility — Nanobots
var nanobots_active: bool = false
var nanobots_timer: Timer
const NANOBOTS_INTERVAL: float = 10.0

# Utility — Shockwave
var has_shockwave_module: bool = false
var shockwave_cooldown: float = 0.0
const SHOCKWAVE_COOLDOWN: float = 8.0
const SHOCKWAVE_SCENE: PackedScene = preload("res://entities/effects/Shockwave.tscn")
signal shockwave_used
signal shockwave_ready

@onready var muzzle: Marker2D = $Muzzle
@onready var vanguard_sprite: Sprite2D = $Vanguard   # название вашего спрайта

var shoot_timer: float = 0.0
var health: int = 3
var invulnerable: bool = false
var blink_tween: Tween


func _ready() -> void:
	add_to_group("player")
	health_changed.emit(health)

	shield_timer = Timer.new()
	shield_timer.name = "ShieldTimer"
	shield_timer.wait_time = SHIELD_COOLDOWN
	shield_timer.one_shot = false
	shield_timer.autostart = false
	add_child(shield_timer)
	shield_timer.timeout.connect(_on_shield_ready)

	energy_shield_recharge_timer = Timer.new()
	energy_shield_recharge_timer.name = "EnergyShieldTimer"
	energy_shield_recharge_timer.wait_time = ENERGY_SHIELD_RECHARGE_TIME
	energy_shield_recharge_timer.one_shot = true
	energy_shield_recharge_timer.autostart = false
	add_child(energy_shield_recharge_timer)
	energy_shield_recharge_timer.timeout.connect(_on_energy_shield_recharged)

	nanobots_timer = Timer.new()
	nanobots_timer.name = "NanobotsTimer"
	nanobots_timer.wait_time = NANOBOTS_INTERVAL
	nanobots_timer.one_shot = false
	nanobots_timer.autostart = false
	add_child(nanobots_timer)
	nanobots_timer.timeout.connect(_on_nanobots_heal)

	# Читаем корабль
	var sm := get_node_or_null("/root/SaveManager")
	if sm:
		current_ship = sm.current_ship
		is_goliath = (current_ship == "goliath")


func set_upgrades(damage_level: int, fire_rate_level: int, health_level: int) -> void:
	bullet_damage = 10 + damage_level * 5
	shoot_delay = max(0.05, 0.2 - fire_rate_level * 0.05)
	max_health = 3 + health_level
	health = max_health
	health_changed.emit(health)
	apply_module_effects()


func apply_module_effects() -> void:
	current_weapon_module = "laser"
	has_shield_module = false
	has_energy_shield = false
	has_reactive_armor = false
	turbo_active = false
	nanobots_active = false
	nanobots_timer.stop()
	has_shockwave_module = false

	var sm := get_node_or_null("/root/SaveManager")
	if sm == null:
		return
	var equipped = sm.equipped_modules
	if equipped == null:
		return

	# Оружие
	var weapon_id = equipped.get("weapon", "")
	if weapon_id == null or str(weapon_id).is_empty():
		weapon_id = "laser"
	current_weapon_module = str(weapon_id)
	match current_weapon_module:
		"rocket":
			shoot_delay = 0.8
		_:
			shoot_delay = 0.2

	# Защита
	var defense_id = str(equipped.get("defense", ""))
	match defense_id:
		"shield":
			has_shield_module = true
			_show_energy_shield_visual(false)
		"energy_shield":
			has_energy_shield = true
			if energy_shield_durability <= 0:
				energy_shield_durability = ENERGY_SHIELD_MAX_DURABILITY
			_show_energy_shield_visual(true)
		"reactive_armor":
			has_reactive_armor = true
			_show_energy_shield_visual(false)

	# Утилита
	var utility_id = str(equipped.get("utility", ""))
	match utility_id:
		"turbo":
			turbo_active = true
		"nanobots":
			nanobots_active = true
			nanobots_timer.start()
	has_shockwave_module = (utility_id == "shockwave")


func _on_nanobots_heal() -> void:
	if nanobots_active and health < max_health:
		health += 1
		health_changed.emit(health)
		var flash = Node2D.new()
		flash.set_script(preload("res://entities/player/HealFlash.gd"))
		get_tree().current_scene.add_child(flash)
		flash.global_position = global_position


func _show_energy_shield_visual(show: bool) -> void:
	if show and energy_shield_visual == null:
		energy_shield_visual = Node2D.new()
		energy_shield_visual.name = "EnergyShieldVisual"
		energy_shield_visual.set_script(preload("res://entities/player/energy_shield_visual.gd"))
		add_child(energy_shield_visual)
	elif not show and energy_shield_visual != null:
		energy_shield_visual.queue_free()
		energy_shield_visual = null


func _process(delta: float) -> void:
	shoot_timer += delta
	if shoot_timer >= shoot_delay:
		shoot_timer = 0.0
		_shoot()
	if shockwave_cooldown > 0.0:
		shockwave_cooldown = max(0.0, shockwave_cooldown - delta)
		if shockwave_cooldown <= 0.0:
			shockwave_ready.emit()
	if dash_cooldown > 0.0:
		dash_cooldown = max(0.0, dash_cooldown - delta)


func _unhandled_input(event: InputEvent) -> void:
	if has_shockwave_module:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_F or event.keycode == KEY_SPACE:
				try_activate_shockwave()
	# Phantom двойное нажатие
	if current_ship == "phantom" and event is InputEventKey and event.pressed and not event.echo:
		var now := Time.get_ticks_msec() / 1000.0
		var dir_key: String = ""
		match event.keycode:
			KEY_A, KEY_LEFT:
				dir_key = "left"
			KEY_D, KEY_RIGHT:
				dir_key = "right"
			KEY_W, KEY_UP:
				dir_key = "up"
			KEY_S, KEY_DOWN:
				dir_key = "down"
		if not dir_key.is_empty():
			var elapsed = now - last_input_time[dir_key]
			last_input_time[dir_key] = now
			if elapsed > 0.0 and elapsed < DOUBLE_TAP_WINDOW and dash_cooldown <= 0.0:
				_do_dash(dir_key)


func _do_dash(dir_key: String) -> void:
	var dash_dir: Vector2 = Vector2.ZERO
	match dir_key:
		"left": dash_dir = Vector2.LEFT
		"right": dash_dir = Vector2.RIGHT
		"up": dash_dir = Vector2.UP
		"down": dash_dir = Vector2.DOWN
	global_position += dash_dir * DASH_DISTANCE
	# Ограничение экраном
	var vps = get_viewport_rect().size
	global_position.x = clamp(global_position.x, MARGIN, vps.x - MARGIN)
	global_position.y = clamp(global_position.y, MARGIN, vps.y - MARGIN)

	invulnerable = true
	# Дэш тоже даёт кратковременную неуязвимость с прохождением сквозь врагов
	collision_layer = 0
	collision_mask = 0
	dash_cooldown = DASH_COOLDOWN_TIME
	vanguard_sprite.modulate = Color(0.6, 0.6, 1, 0.8)
	await get_tree().create_timer(DASH_INVULN_DURATION).timeout
	invulnerable = false
	collision_layer = 1
	collision_mask = 1
	vanguard_sprite.modulate = Color.WHITE


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
	var input_vector := Input.get_vector("left", "right", "up", "down")
	var speed_mult = TURBO_SPEED_MULTIPLIER if turbo_active else 1.0
	if is_goliath:
		speed_mult *= GOLIATH_SPEED_MULTIPLIER
	velocity = input_vector * SPEED * speed_mult
	move_and_slide()

	# Ограничение экраном
	var vps = get_viewport_rect().size
	global_position.x = clamp(global_position.x, MARGIN, vps.x - MARGIN)
	global_position.y = clamp(global_position.y, MARGIN, vps.y - MARGIN)
	# Урон игроку от столкновений с врагами теперь обрабатывается через Area2D Hitbox
	# на каждом враге (см. Boss.gd, Fighter.gd, Scout.gd -> _on_hitbox_body_entered).


func _shoot() -> void:
	var bullet_scene = preload("res://entities/projectiles/PlayerBullet.tscn")
	if not bullet_scene:
		return
	if current_weapon_module == "rocket":
		var bullet = bullet_scene.instantiate()
		bullet.global_position = muzzle.global_position
		bullet.damage = bullet_damage * 3
		get_tree().current_scene.add_child(bullet)
	elif current_weapon_module == "shotgun":
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
		var bullet = bullet_scene.instantiate()
		bullet.global_position = muzzle.global_position
		bullet.damage = bullet_damage
		get_tree().current_scene.add_child(bullet)


func take_damage(amount: int) -> void:
	if invulnerable:
		return

	if has_energy_shield and energy_shield_durability > 0:
		var absorbed = min(amount, energy_shield_durability)
		energy_shield_durability -= absorbed
		var sm = get_node_or_null("/root/SaveManager")
		if sm:
			sm.add_credits(absorbed * 5)
		if energy_shield_visual != null:
			energy_shield_visual.modulate = Color(0.3, 0.5, 1, 0.6)
			var tw = create_tween()
			tw.tween_property(energy_shield_visual, "modulate", Color(0.2, 0.4, 1, 0.35), 0.15)
		if energy_shield_durability <= 0:
			energy_shield_recharge_timer.start()
		return

	if has_reactive_armor:
		amount = max(1, int(ceil(amount * 0.5)))
		_deal_damage_to_enemies_in_radius()
		_spawn_reactive_blast()

	if has_shield_module and is_shield_ready:
		is_shield_ready = false
		shield_timer.start()
		_spawn_shield_flash()
		shield_activated.emit()
		return

	self.health -= amount
	health_changed.emit(health)
	invulnerable = true
	# Отключаем collision_layer и collision_mask чтобы игрок "пролетал насквозь" всех врагов
	# (Area2D на врагах перестаёт детектировать тело, и move_and_slide не скользит
	#  по коллайдерам врагов — тело становится полностью "призрачным")
	collision_layer = 0
	collision_mask = 0
	_start_blinking()
	var main = get_tree().current_scene
	if main and main.has_method("shake_camera"):
		main.shake_camera(0.2, 5.0)
	if health <= 0:
		die()
		return
	await get_tree().create_timer(INVULN_DURATION).timeout
	invulnerable = false
	# Восстанавливаем collision_layer и collision_mask после окончания неуязвимости
	collision_layer = 1
	collision_mask = 1
	_stop_blinking()


func _deal_damage_to_enemies_in_radius() -> void:
	var main = get_tree().current_scene
	if not main:
		return
	for child in main.get_children():
		if child is CharacterBody2D and child != self:
			if child.has_method("take_damage") and global_position.distance_to(child.global_position) <= REACTIVE_ARMOR_RADIUS:
				child.take_damage(REACTIVE_ARMOR_DAMAGE)


func _spawn_reactive_blast() -> void:
	var blast = Node2D.new()
	blast.global_position = global_position
	blast.set_script(preload("res://entities/player/ReactiveBlast.gd"))
	get_tree().current_scene.add_child(blast)


func _on_shield_ready() -> void:
	is_shield_ready = true
	shield_recharged.emit()


func _on_energy_shield_recharged() -> void:
	energy_shield_durability = ENERGY_SHIELD_MAX_DURABILITY


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
	blink_tween.tween_property(vanguard_sprite, "modulate:a", 0.3, 0.1)
	blink_tween.tween_property(vanguard_sprite, "modulate:a", 1.0, 0.1)
	blink_tween.set_loops()


func _stop_blinking() -> void:
	vanguard_sprite.modulate.a = 1.0
	if blink_tween:
		blink_tween.kill()
		blink_tween = null
