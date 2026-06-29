extends CharacterBody2D

signal player_died
signal health_changed(new_health: int)
signal shield_activated
signal shield_recharged
signal shockwave_used
signal shockwave_ready
signal goliath_charge_used
signal goliath_charge_ready
signal homing_salvo_used
signal homing_salvo_ready
signal dash_used
signal dash_ready

const SPEED: float = 400.0
const MARGIN: float = 20.0
const INVULN_DURATION: float = 1.5

# Phantom — dash
const DASH_COOLDOWN_TIME: float = 3.0
const DASH_DISTANCE: float = 150.0
const DOUBLE_TAP_WINDOW: float = 0.3
const DASH_INVULN_DURATION: float = 0.2

# Goliath
const GOLIATH_SPEED_MULTIPLIER: float = 0.7

# === Goliath — рывок со щитом ===
const GOLIATH_CHARGE_DISTANCE: float = 300.0
const GOLIATH_CHARGE_DURATION: float = 0.5
const GOLIATH_CHARGE_COOLDOWN: float = 6.0
const GOLIATH_CHARGE_DAMAGE: int = 60

var goliath_charge_cooldown: float = 0.0
var goliath_charge_active: bool = false
var goliath_charge_tween: Tween = null

var bullet_damage: int = 10
var shoot_delay: float = 0.2
var max_health: int = 3

var current_weapon_module: String = ""
var current_ship: String = "vanguard"
var is_goliath: bool = false

# === Оружие: константы ===
const LASER_MK2_DAMAGE: int = 8
const LASER_MK2_SHOOT_DELAY: float = 0.222
const LASER_MK2_SPREAD_ANGLE: float = 0.07
const LASER_PIERCE_DAMAGE: int = 15
const LASER_PIERCE_SHOOT_DELAY: float = 0.25
const LASER_PLASMA_DAMAGE: int = 20
const LASER_PLASMA_BASE_SHOOT_DELAY: float = 0.4
const LASER_PLASMA_MIN_SHOOT_DELAY: float = 0.15
const LASER_PLASMA_HOMING_RADIUS: float = 200.0
const LASER_PLASMA_HOMING_TURN: float = 4.0
const LASER_PLASMA_STACK_PER_HIT: float = 0.02
const LASER_PLASMA_STACK_RESET_TIME: float = 2.0

var plasma_stack: int = 0
var plasma_reset_timer: float = 0.0
var laser_mk2_muzzle: Marker2D = null
var laser_mk2_muzzle_left: Marker2D = null

# === Дробовики ===
const WHISTLE_PELLETS: int = 5
const WHISTLE_PELLET_DAMAGE: int = 6
const WHISTLE_HALF_SPREAD_RAD: float = 0.3927
const WHISTLE_SHOOT_DELAY: float = 0.35
const WHISTLE_PELLET_MAX_DISTANCE: float = 375.0
const WHISTLE_PELLET_SPEED: float = 550.0

const PRESSURE_PELLETS: int = 3
const PRESSURE_PELLET_DAMAGE: int = 15
const PRESSURE_HALF_SPREAD_RAD: float = 0.1745
const PRESSURE_SHOOT_DELAY: float = 0.6
const PRESSURE_PELLET_MAX_DISTANCE: float = 525.0
const PRESSURE_PELLET_SPEED: float = 700.0

const HEAVY_PELLETS: int = 5
const HEAVY_PELLET_DAMAGE: int = 8
const HEAVY_SHOOT_DELAY: float = 0.5
const HEAVY_HALF_SPREAD_RAD: float = 0.6109
const HEAVY_PELLET_MAX_DISTANCE: float = 330.0
const HEAVY_PELLET_SPEED: float = 550.0

var current_pellet_color: Color = Color.WHITE
var current_pellet_rarity: String = "common"

# === Ракеты ===
const ROCKET_DAMAGE: int = 30
const ROCKET_MK2_HOMING_RADIUS: float = 100.0
const ROCKET_MK2_HOMING_TURN: float = 3.0
const ROCKET_HOMING_RADIUS: float = 200.0
const ROCKET_HOMING_TURN: float = 5.0
const HOMING_SALVO_COUNT: int = 5
const HOMING_SALVO_SPACING: float = 20.0
const HOMING_SALVO_DAMAGE: int = 30
const HOMING_SALVO_COOLDOWN: float = 10.0
const NUKE_NORMAL_COUNT: int = 3
const NUKE_BIG_COUNT: int = 5
const NUKE_SPREAD: float = 0.436
const NUKE_DAMAGE: int = 40
const NUKE_BIG_COOLDOWN: float = 4.0
var homing_salvo_cooldown: float = 0.0
var nuke_big_shot_cooldown: float = 0.0
var nuke_shot_counter: int = 0

# Phantom dash — отслеживание последнего нажатия по направлению
var _dash_last_press: Dictionary = {"left": 0.0, "right": 0.0, "up": 0.0, "down": 0.0}
var dash_cooldown: float = 0.0

# === Defense — новые модули ===
var has_light_armor: bool = false
var has_shield_module: bool = false
var is_shield_ready: bool = true
var shield_durability: int = 0
const SHIELD_MAX_DURABILITY: int = 5
var shield_recharge_timer: Timer

var has_composite_armor: bool = false
var composite_hit_counter: int = 0
const COMPOSITE_ARMOR_INTERVAL: int = 3

var has_forsage: bool = false
var forsage_timer: float = 0.0
const FORSAGE_DURATION: float = 2.0
const FORSAGE_SPEED_MULT: float = 1.5

var has_tactical_accelerator: bool = false
var tactical_accel_timer: float = 0.0
var tactical_accel_active: bool = false
const TACTICAL_ACCEL_DURATION: float = 3.0
const TACTICAL_ACCEL_FIRE_MULT: float = 0.7
var tactical_accel_original_delay: float = 0.2

var has_diffusor: bool = false
const DIFFUSOR_RADIUS: float = 200.0
const DIFFUSOR_DAMAGE: int = 10
const DIFFUSOR_CHANCE: float = 1.0

var has_cocoon_shield: bool = false
var cocoon_shield_ready: bool = true
var cocoon_cd_timer: Timer
const COCOON_CD: float = 25.0
var cocoon_revive_used: bool = false

# === Utility ===
var turbo_active: bool = false
const TURBO_SPEED_MULTIPLIER: float = 1.3
var nanobots_active: bool = false
var nanobots_timer: Timer
const NANOBOTS_INTERVAL: float = 20.0
var has_shockwave_module: bool = false
var shockwave_cooldown: float = 0.0
const SHOCKWAVE_COOLDOWN: float = 8.0
const SHOCKWAVE_SCENE: PackedScene = preload("res://entities/effects/Shockwave.tscn")

# Drone
var drone_count: int = 0
var drone_copy_weapon: bool = false
var drone_catch_projectiles: bool = false
const DRONE_SCENE: PackedScene = preload("res://entities/effects/Drone.tscn")
var _drone_instances: Array[Node] = []

# Shield visuals
const COCOON_SHIELD_SCENE: PackedScene = preload("res://entities/projectiles/CocoonShieldVisual.tscn")
var _cocoon_shield_instance: Node2D = null
var _common_shield_instance: Node2D = null

@onready var muzzle: Marker2D = $Muzzle
@onready var vanguard_sprite: Sprite2D = $Vanguard
@onready var vanguard_v2_sprite: AnimatedSprite2D = $VanguardV2
@onready var vanguard_v3_sprite: AnimatedSprite2D = $VanguardV3
@onready var phantom_sprite: AnimatedSprite2D = $Phantom
@onready var phantom_v2_sprite: AnimatedSprite2D = $PhantomV2
@onready var phantom_v3_sprite: AnimatedSprite2D = $PhantomV3
@onready var goliath_sprite: AnimatedSprite2D = $Goliath
@onready var goliath_v2_sprite: AnimatedSprite2D = $GoliathV2
@onready var goliath_v3_sprite: AnimatedSprite2D = $GoliathV3
@onready var default_collision: CollisionShape2D = $CollisionShape2D
@onready var goliath_collision: CollisionPolygon2D = $GoliathCollisionPolygon2D
@onready var shoot_sound: AudioStreamPlayer2D = $ShootSound
@onready var roket_sound: AudioStreamPlayer2D = $RoketSound
@onready var shot_gun_sound: AudioStreamPlayer2D = $ShotGunSound
@onready var goliath_shield: AnimatedSprite2D = $GoliathShield
@onready var goliath_shield_area: Area2D = $GoliathShieldArea
var current_ship_sprite: Node2D = null
var _skin_instance: Node2D = null

var shoot_timer: float = 0.0
var health: int = 3
var invulnerable: bool = false
var blink_tween: Tween
var _skin_speed_mult: float = 1.0
var shooting_disabled: bool = false


func _ready() -> void:
	collision_layer = 3
	collision_mask = 1

	add_to_group("player")
	health_changed.emit(health)

	if goliath_shield:
		goliath_shield.visible = false
		goliath_shield.modulate.a = 1.0
	if goliath_shield_area:
		goliath_shield_area.monitoring = false
		goliath_shield_area.monitorable = false
		if goliath_shield_area.body_entered.is_connected(_on_goliath_shield_body_entered):
			goliath_shield_area.body_entered.disconnect(_on_goliath_shield_body_entered)
		if goliath_shield_area.area_entered.is_connected(_on_goliath_shield_area_entered):
			goliath_shield_area.area_entered.disconnect(_on_goliath_shield_area_entered)
		goliath_shield_area.body_entered.connect(_on_goliath_shield_body_entered)
		goliath_shield_area.area_entered.connect(_on_goliath_shield_area_entered)

	shield_recharge_timer = Timer.new()
	shield_recharge_timer.name = "ShieldRechargeTimer"
	shield_recharge_timer.wait_time = 10.0
	shield_recharge_timer.one_shot = true
	shield_recharge_timer.autostart = false
	add_child(shield_recharge_timer)
	shield_recharge_timer.timeout.connect(_on_shield_recharged)

	cocoon_cd_timer = Timer.new()
	cocoon_cd_timer.name = "CocoonCDTimer"
	cocoon_cd_timer.wait_time = COCOON_CD
	cocoon_cd_timer.one_shot = true
	cocoon_cd_timer.autostart = false
	add_child(cocoon_cd_timer)
	cocoon_cd_timer.timeout.connect(_on_cocoon_ready)

	if COCOON_SHIELD_SCENE:
		_cocoon_shield_instance = COCOON_SHIELD_SCENE.instantiate()
		add_child(_cocoon_shield_instance)
		_cocoon_shield_instance.visible = false

	if COCOON_SHIELD_SCENE:
		_common_shield_instance = COCOON_SHIELD_SCENE.instantiate()
		add_child(_common_shield_instance)
		if _common_shield_instance.has_method(&"set_shield_color"):
			_common_shield_instance.set_shield_color(Color(0.37, 0.556, 0.969, 1.0))
		_common_shield_instance.visible = false

	nanobots_timer = Timer.new()
	nanobots_timer.name = "NanobotsTimer"
	nanobots_timer.wait_time = NANOBOTS_INTERVAL
	nanobots_timer.one_shot = false
	nanobots_timer.autostart = false
	add_child(nanobots_timer)
	nanobots_timer.timeout.connect(_on_nanobots_heal)

	var sm := get_node_or_null("/root/SaveManager")
	if sm:
		current_ship = sm.current_ship
		is_goliath = (current_ship == "goliath")
	_show_current_ship()


func set_upgrades(health_level: int) -> void:
	bullet_damage = 10
	shoot_delay = 0.2
	max_health = 3 + health_level
	health = max_health
	health_changed.emit(health)
	apply_module_effects()
	_apply_skin_bonuses()


func apply_module_effects() -> void:
	current_weapon_module = "laser"
	has_light_armor = false
	has_shield_module = false
	has_composite_armor = false
	has_forsage = false
	has_tactical_accelerator = false
	has_diffusor = false
	has_cocoon_shield = false
	turbo_active = false
	nanobots_active = false
	nanobots_timer.stop()
	has_shockwave_module = false
	drone_count = 0
	drone_copy_weapon = false
	drone_catch_projectiles = false
	for d in _drone_instances:
		if d and is_instance_valid(d):
			d.queue_free()
	_drone_instances.clear()

	var sm := get_node_or_null("/root/SaveManager")
	if sm == null:
		return
	var equipped = sm.equipped_modules
	if equipped == null:
		return

	var weapon_id = equipped.get("weapon", "")
	if weapon_id == null or str(weapon_id).is_empty():
		weapon_id = "laser"
	current_weapon_module = str(weapon_id)
	var weapon_module_path: String = "res://data/modules/%s.tres" % current_weapon_module
	if ResourceLoader.exists(weapon_module_path):
		var module_data: Resource = load(weapon_module_path)
		if module_data != null and "pellet_color" in module_data:
			current_pellet_color = Color(module_data.pellet_color)
		else:
			current_pellet_color = Color.WHITE
		if module_data != null and "rarity" in module_data:
			current_pellet_rarity = str(module_data.rarity)
		else:
			current_pellet_rarity = "common"
	else:
		current_pellet_color = Color.WHITE
		current_pellet_rarity = "common"
	match current_weapon_module:
		"rocket": shoot_delay = 1.0
		"rocket_mk2": shoot_delay = 1.0
		"rocket_homing": shoot_delay = 1.0
		"rocket_nuke": shoot_delay = 1.0
		"shotgun": shoot_delay = 0.5
		"shotgun_whistle": shoot_delay = WHISTLE_SHOOT_DELAY
		"shotgun_pressure": shoot_delay = PRESSURE_SHOOT_DELAY
		"shotgun_heavy": shoot_delay = HEAVY_SHOOT_DELAY
		"laser_mk2":
			shoot_delay = LASER_MK2_SHOOT_DELAY
			_ensure_laser_mk2_muzzles()
		"laser_pierce": shoot_delay = LASER_PIERCE_SHOOT_DELAY
		"laser_plasma":
			shoot_delay = LASER_PLASMA_BASE_SHOOT_DELAY
			plasma_stack = 0
			plasma_reset_timer = 0.0
		_:
			shoot_delay = 0.2

	var defense_id = str(equipped.get("defense", ""))
	match defense_id:
		"light_armor":
			has_light_armor = true
			max_health = 3 + (get_node_or_null("/root/SaveManager") as Node).health_upgrade_level if has_node("/root/SaveManager") else 3
			max_health += 1
			health = max_health
			health_changed.emit(health)
		"shield":
			has_shield_module = true
			shield_durability = SHIELD_MAX_DURABILITY
			if _common_shield_instance and is_instance_valid(_common_shield_instance):
				_common_shield_instance.is_goliath = is_goliath
				_common_shield_instance.activate()
		"composite_armor":
			has_composite_armor = true
			composite_hit_counter = 0
		"forsage":
			has_forsage = true
		"tactical_accelerator":
			has_tactical_accelerator = true
			tactical_accel_active = false
			tactical_accel_timer = 0.0
			tactical_accel_original_delay = shoot_delay
		"diffusor":
			has_diffusor = true
		"cocoon_shield":
			has_cocoon_shield = true
			cocoon_shield_ready = true
			if _cocoon_shield_instance and is_instance_valid(_cocoon_shield_instance):
				_cocoon_shield_instance.is_goliath = is_goliath
				_cocoon_shield_instance.activate()

	var utility_id = str(equipped.get("utility", ""))
	match utility_id:
		"turbo":
			turbo_active = true
		"nanobots":
			nanobots_active = true
			nanobots_timer.start()
		"drone":
			drone_count = 1
			drone_copy_weapon = false
			drone_catch_projectiles = false
			_spawn_drones()
		"drone_rare":
			drone_count = 2
			drone_copy_weapon = false
			drone_catch_projectiles = false
			_spawn_drones()
		"drone_epic":
			drone_count = 2
			drone_copy_weapon = true
			drone_catch_projectiles = false
			_spawn_drones()
		"drone_legendary":
			drone_count = 3
			drone_copy_weapon = true
			drone_catch_projectiles = true
			_spawn_drones()
	has_shockwave_module = (utility_id == "shockwave")
	
	var sm_check := get_node_or_null("/root/SaveManager")
	if sm_check:
		sm_check.on_achievement_progress_check()


func _apply_vanguard_skin(skin_index: int) -> void:
	vanguard_sprite.visible = false
	vanguard_v2_sprite.visible = false
	vanguard_v3_sprite.visible = false
	match skin_index:
		0:
			vanguard_sprite.visible = true
			current_ship_sprite = vanguard_sprite
		1:
			vanguard_v2_sprite.visible = true
			current_ship_sprite = vanguard_v2_sprite
		2:
			vanguard_v3_sprite.visible = true
			current_ship_sprite = vanguard_v3_sprite
		_:
			vanguard_sprite.visible = true
			current_ship_sprite = vanguard_sprite


func _apply_phantom_skin(skin_index: int) -> void:
	phantom_sprite.visible = false
	phantom_v2_sprite.visible = false
	phantom_v3_sprite.visible = false
	if _skin_instance:
		_skin_instance.queue_free()
		_skin_instance = null
	match skin_index:
		0:
			phantom_sprite.visible = true
			current_ship_sprite = phantom_sprite
		1:
			phantom_v2_sprite.visible = true
			current_ship_sprite = phantom_v2_sprite
		2:
			if not _try_instantiate_skin_scene("skin_phantom_2"):
				phantom_v3_sprite.visible = true
				current_ship_sprite = phantom_v3_sprite
		_:
			phantom_sprite.visible = true
			current_ship_sprite = phantom_sprite


func _try_instantiate_skin_scene(skin_visuals_id: String) -> bool:
	var visuals_path := "res://data/visuals/%s_visuals.tres" % skin_visuals_id
	if not ResourceLoader.exists(visuals_path):
		return false
	var visuals: Resource = load(visuals_path)
	if visuals == null or not "skin_scene" in visuals:
		return false
	var scene: PackedScene = visuals.skin_scene
	if scene == null:
		return false
	_skin_instance = scene.instantiate()
	if _skin_instance == null:
		return false
	add_child(_skin_instance)
	current_ship_sprite = _find_sprite_node(_skin_instance)
	return true


func _find_sprite_node(root: Node) -> Node2D:
	for child in root.get_children():
		if child is AnimatedSprite2D or child is Sprite2D:
			return child
	return root


func _apply_goliath_skin(skin_index: int) -> void:
	goliath_sprite.visible = false
	goliath_v2_sprite.visible = false
	goliath_v3_sprite.visible = false
	match skin_index:
		0:
			goliath_sprite.visible = true
			current_ship_sprite = goliath_sprite
		1:
			goliath_v2_sprite.visible = true
			current_ship_sprite = goliath_v2_sprite
		2:
			goliath_v3_sprite.visible = true
			current_ship_sprite = goliath_v3_sprite
		_:
			goliath_sprite.visible = true
			current_ship_sprite = goliath_sprite


func _show_current_ship() -> void:
	vanguard_sprite.visible = false
	vanguard_v2_sprite.visible = false
	vanguard_v3_sprite.visible = false
	phantom_sprite.visible = false
	phantom_v2_sprite.visible = false
	phantom_v3_sprite.visible = false
	goliath_sprite.visible = false
	goliath_v2_sprite.visible = false
	goliath_v3_sprite.visible = false
	
	match current_ship:
		"vanguard":
			default_collision.disabled = false
			goliath_collision.disabled = true
			var sm := get_node_or_null("/root/SaveManager")
			var skin_idx: int = 0
			if sm:
				skin_idx = sm.get_current_skin("vanguard")
			_apply_vanguard_skin(skin_idx)
		"phantom":
			default_collision.disabled = false
			goliath_collision.disabled = true
			var sm := get_node_or_null("/root/SaveManager")
			var skin_idx: int = 0
			if sm:
				skin_idx = sm.get_current_skin("phantom")
			_apply_phantom_skin(skin_idx)
		"goliath":
			default_collision.disabled = true
			goliath_collision.disabled = false
			var sm := get_node_or_null("/root/SaveManager")
			var skin_idx: int = 0
			if sm:
				skin_idx = sm.get_current_skin("goliath")
			_apply_goliath_skin(skin_idx)


func _get_blink_target() -> Node2D:
	return current_ship_sprite if current_ship_sprite else vanguard_sprite


func _ensure_laser_mk2_muzzles() -> void:
	if laser_mk2_muzzle == null:
		laser_mk2_muzzle = Marker2D.new()
		laser_mk2_muzzle.name = "LaserMk2Muzzle"
		laser_mk2_muzzle.position = Vector2(10, -20)
		add_child(laser_mk2_muzzle)
	if laser_mk2_muzzle_left == null:
		laser_mk2_muzzle_left = Marker2D.new()
		laser_mk2_muzzle_left.name = "LaserMk2MuzzleLeft"
		laser_mk2_muzzle_left.position = Vector2(-10, -20)
		add_child(laser_mk2_muzzle_left)


func get_weapon_module_id() -> String:
	return current_weapon_module


func _spawn_drones() -> void:
	if not DRONE_SCENE:
		return
	for d in _drone_instances:
		if d and is_instance_valid(d):
			d.queue_free()
	_drone_instances.clear()
	for i in range(drone_count):
		var drone = DRONE_SCENE.instantiate()
		drone.copy_weapon = drone_copy_weapon
		drone.catch_projectiles = drone_catch_projectiles
		drone.weapon_module_id = current_weapon_module
		drone.set_meta("orbit_offset", float(i) / float(drone_count) * TAU)
		add_child(drone)
		_drone_instances.append(drone)


func _on_nanobots_heal() -> void:
	if nanobots_active and health < max_health:
		health += 1
		health_changed.emit(health)
		var sm := get_node_or_null("/root/SaveManager")
		if sm:
			sm.tmp_nanobots_healed += 1
			if sm.tmp_nanobots_healed >= 20:
				sm.unlock_achievement("nanobot_healer")
		var flash = Node2D.new()
		flash.set_script(preload("res://entities/player/HealFlash.gd"))
		get_tree().current_scene.add_child(flash)
		flash.global_position = global_position


func _input(event: InputEvent) -> void:
	# Phantom dash — двойной тап WASD/стрелок (через Input Map, без раскладки)
	_detect_dash_input(event)


func _process(delta: float) -> void:
	# Плазма
	if current_weapon_module == "laser_plasma":
		if plasma_reset_timer > 0.0:
			plasma_reset_timer = max(0.0, plasma_reset_timer - delta)
			if plasma_reset_timer <= 0.0 and plasma_stack > 0:
				plasma_stack = 0
		var stack_fraction: float = float(plasma_stack) * LASER_PLASMA_STACK_PER_HIT
		shoot_delay = lerp(LASER_PLASMA_BASE_SHOOT_DELAY, LASER_PLASMA_MIN_SHOOT_DELAY, clamp(stack_fraction / 0.5, 0.0, 1.0))

	if has_forsage and forsage_timer > 0.0:
		forsage_timer = max(0.0, forsage_timer - delta)

	if has_tactical_accelerator and tactical_accel_active:
		tactical_accel_timer = max(0.0, tactical_accel_timer - delta)
		if tactical_accel_timer <= 0.0:
			tactical_accel_active = false
			shoot_delay = tactical_accel_original_delay

	if goliath_charge_cooldown > 0.0:
		goliath_charge_cooldown = max(0.0, goliath_charge_cooldown - delta)
		if goliath_charge_cooldown <= 0.0:
			goliath_charge_ready.emit()

	if not shooting_disabled:
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
		if dash_cooldown <= 0.0:
			dash_ready.emit()
	if homing_salvo_cooldown > 0.0:
		homing_salvo_cooldown = max(0.0, homing_salvo_cooldown - delta)
		if homing_salvo_cooldown <= 0.0:
			homing_salvo_ready.emit()
	if nuke_big_shot_cooldown > 0.0:
		nuke_big_shot_cooldown = max(0.0, nuke_big_shot_cooldown - delta)

	if _cocoon_shield_instance and is_instance_valid(_cocoon_shield_instance) and _cocoon_shield_instance.visible:
		if current_ship_sprite and is_instance_valid(current_ship_sprite):
			_cocoon_shield_instance.global_position = current_ship_sprite.global_position
	if _common_shield_instance and is_instance_valid(_common_shield_instance) and _common_shield_instance.visible:
		if current_ship_sprite and is_instance_valid(current_ship_sprite):
			_common_shield_instance.global_position = current_ship_sprite.global_position
	
	# Dash теперь обрабатывается в _input(), не здесь


# ============================================================
# Phantom dash — двойное нажатие на WASD/стрелки
# Работает через Input Map, не зависит от раскладки клавиатуры
# ============================================================
func _detect_dash_input(event: InputEvent) -> void:
	if current_ship != "phantom":
		return
	if not event.is_action_pressed("left") and not event.is_action_pressed("right") \
		and not event.is_action_pressed("up") and not event.is_action_pressed("down"):
		return
	
	var now := Time.get_ticks_msec() / 1000.0
	var dir_key: String = ""
	
	if event.is_action_pressed("left"):
		dir_key = "left"
	elif event.is_action_pressed("right"):
		dir_key = "right"
	elif event.is_action_pressed("up"):
		dir_key = "up"
	elif event.is_action_pressed("down"):
		dir_key = "down"
	
	if not dir_key.is_empty():
		var elapsed = now - _dash_last_press[dir_key]
		_dash_last_press[dir_key] = now
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
	_finish_dash()


func dash_to_target(target_global_pos: Vector2) -> void:
	if dash_cooldown > 0.0:
		return
	if current_ship != "phantom":
		return
	var dir_to_target: Vector2 = (target_global_pos - global_position).normalized()
	global_position += dir_to_target * DASH_DISTANCE
	_finish_dash()


func _finish_dash() -> void:
	var vps = get_viewport_rect().size
	global_position.x = clamp(global_position.x, MARGIN, vps.x - MARGIN)
	global_position.y = clamp(global_position.y, MARGIN, vps.y - MARGIN)
	dash_used.emit()
	invulnerable = true
	collision_layer = 2
	collision_mask = 0
	dash_cooldown = DASH_COOLDOWN_TIME
	var blink_target := _get_blink_target()
	blink_target.modulate = Color(0.6, 0.6, 1, 0.8)
	
	if current_ship == "phantom":
		var sm := get_node_or_null("/root/SaveManager")
		if sm:
			sm.tmp_phantom_dashes += 1
			if sm.tmp_phantom_dashes >= 50:
				sm.unlock_achievement("phantom_dasher")
	
	await get_tree().create_timer(DASH_INVULN_DURATION).timeout
	invulnerable = false
	collision_layer = 3
	collision_mask = 1
	blink_target.modulate = Color.WHITE


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
	var sm := get_node_or_null("/root/SaveManager")
	if sm:
		sm.tmp_shockwave_used += 1
		if sm.tmp_shockwave_used >= 20:
			sm.unlock_achievement("shockwave_master")
	return true


func _physics_process(_delta: float) -> void:
	var input_vector := Input.get_vector("left", "right", "up", "down")
	
	var speed_mult = TURBO_SPEED_MULTIPLIER if turbo_active else 1.0
	if has_forsage and forsage_timer > 0.0:
		speed_mult *= FORSAGE_SPEED_MULT
	if is_goliath:
		speed_mult *= GOLIATH_SPEED_MULTIPLIER
	speed_mult *= _skin_speed_mult
	velocity = input_vector * SPEED * speed_mult
	move_and_slide()
	var vps = get_viewport_rect().size
	global_position.x = clamp(global_position.x, MARGIN, vps.x - MARGIN)
	global_position.y = clamp(global_position.y, MARGIN, vps.y - MARGIN)


const ROCKET_SCENE: PackedScene = preload("res://entities/projectiles/PlayerRocket.tscn")
const PELLET_SCENE: PackedScene = preload("res://entities/projectiles/PlayerPellet.tscn")


func _shoot() -> void:
	var bullet_scene = preload("res://entities/projectiles/PlayerBullet.tscn")
	if not bullet_scene:
		return
	if current_weapon_module == "rocket":
		if roket_sound: roket_sound.play()
		_spawn_rocket(muzzle.global_position, ROCKET_DAMAGE, false, 0.0, 0.0)
		return
	if current_weapon_module == "rocket_mk2":
		if roket_sound: roket_sound.play()
		_spawn_rocket(muzzle.global_position, ROCKET_DAMAGE, true, ROCKET_MK2_HOMING_RADIUS, ROCKET_MK2_HOMING_TURN)
		return
	if current_weapon_module == "rocket_homing":
		if roket_sound: roket_sound.play()
		_spawn_rocket(muzzle.global_position, ROCKET_DAMAGE, true, ROCKET_HOMING_RADIUS, ROCKET_HOMING_TURN)
		return
	if current_weapon_module == "rocket_nuke":
		if roket_sound: roket_sound.play()
		var can_big := nuke_big_shot_cooldown <= 0.0
		var want_big := (nuke_shot_counter >= 2) and can_big
		var count: int = NUKE_BIG_COUNT if want_big else NUKE_NORMAL_COUNT
		if want_big:
			nuke_big_shot_cooldown = NUKE_BIG_COOLDOWN
			nuke_shot_counter = 0
		else:
			nuke_shot_counter += 1
		var start_angle := -NUKE_SPREAD * (count - 1) / 2.0
		for i in count:
			var dir := Vector2.UP.rotated(start_angle + i * NUKE_SPREAD)
			var rocket = ROCKET_SCENE.instantiate()
			rocket.global_position = muzzle.global_position
			rocket.damage = NUKE_DAMAGE
			rocket.direction = dir
			rocket.straighten_after = 0.6
			rocket.straighten_turn = 3.0
			get_tree().current_scene.add_child(rocket)
		return
	if current_weapon_module == "shotgun":
		if shot_gun_sound: shot_gun_sound.play()
		const SHOTGUN_PELLETS: int = 7
		const SHOTGUN_PELLET_DAMAGE: int = 5
		const SHOTGUN_HALF_SPREAD_RAD: float = 0.5236
		for i in SHOTGUN_PELLETS:
			var dir = Vector2.UP.rotated(randf_range(-SHOTGUN_HALF_SPREAD_RAD, SHOTGUN_HALF_SPREAD_RAD))
			var pellet = PELLET_SCENE.instantiate()
			pellet.global_position = muzzle.global_position + Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0))
			pellet.damage = SHOTGUN_PELLET_DAMAGE
			pellet.direction = dir
			pellet.modulate = current_pellet_color
			pellet.rarity = current_pellet_rarity
			get_tree().current_scene.add_child(pellet)
		return
	if current_weapon_module == "shotgun_whistle":
		if shot_gun_sound: shot_gun_sound.play()
		for i in WHISTLE_PELLETS:
			var dir = Vector2.UP.rotated(randf_range(-WHISTLE_HALF_SPREAD_RAD, WHISTLE_HALF_SPREAD_RAD))
			var pellet = PELLET_SCENE.instantiate()
			pellet.global_position = muzzle.global_position + Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0))
			pellet.damage = WHISTLE_PELLET_DAMAGE
			pellet.direction = dir
			pellet.max_distance = WHISTLE_PELLET_MAX_DISTANCE
			pellet.speed = WHISTLE_PELLET_SPEED
			pellet.modulate = current_pellet_color
			pellet.rarity = current_pellet_rarity
			get_tree().current_scene.add_child(pellet)
		return
	if current_weapon_module == "shotgun_pressure":
		if shot_gun_sound: shot_gun_sound.play()
		for i in PRESSURE_PELLETS:
			var dir = Vector2.UP.rotated(randf_range(-PRESSURE_HALF_SPREAD_RAD, PRESSURE_HALF_SPREAD_RAD))
			var pellet = PELLET_SCENE.instantiate()
			pellet.global_position = muzzle.global_position + Vector2(randf_range(-1.5, 1.5), randf_range(-1.5, 1.5))
			pellet.damage = PRESSURE_PELLET_DAMAGE
			pellet.direction = dir
			pellet.max_distance = PRESSURE_PELLET_MAX_DISTANCE
			pellet.speed = PRESSURE_PELLET_SPEED
			pellet.pierce = true
			pellet.modulate = current_pellet_color
			pellet.rarity = current_pellet_rarity
			get_tree().current_scene.add_child(pellet)
		return
	if current_weapon_module == "shotgun_heavy":
		if shot_gun_sound: shot_gun_sound.play()
		for i in HEAVY_PELLETS:
			var dir = Vector2.UP.rotated(randf_range(-HEAVY_HALF_SPREAD_RAD, HEAVY_HALF_SPREAD_RAD))
			var pellet = PELLET_SCENE.instantiate()
			pellet.global_position = muzzle.global_position + Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0))
			pellet.damage = HEAVY_PELLET_DAMAGE
			pellet.direction = dir
			pellet.max_distance = HEAVY_PELLET_MAX_DISTANCE
			pellet.speed = HEAVY_PELLET_SPEED
			pellet.modulate = current_pellet_color
			pellet.rarity = current_pellet_rarity
			pellet.kartrich_burst = true
			get_tree().current_scene.add_child(pellet)
		return
	if current_weapon_module == "laser_mk2":
		if shoot_sound: shoot_sound.play()
		_ensure_laser_mk2_muzzles()
		_spawn_laser_bullet(laser_mk2_muzzle_left, Vector2.UP.rotated(-LASER_MK2_SPREAD_ANGLE), LASER_MK2_DAMAGE)
		_spawn_laser_bullet(laser_mk2_muzzle, Vector2.UP.rotated(LASER_MK2_SPREAD_ANGLE), LASER_MK2_DAMAGE)
		return
	if current_weapon_module == "laser_pierce":
		if shoot_sound: shoot_sound.play()
		_spawn_laser_bullet(muzzle, Vector2.UP, LASER_PIERCE_DAMAGE, true)
		return
	if current_weapon_module == "laser_plasma":
		if shoot_sound: shoot_sound.play()
		_spawn_plasma_bullet()
		return
	if shoot_sound: shoot_sound.play()
	var bullet = bullet_scene.instantiate()
	bullet.global_position = muzzle.global_position
	bullet.damage = bullet_damage
	get_tree().current_scene.add_child(bullet)


func _spawn_rocket(spawn_pos: Vector2, dmg: int, homing: bool, homing_radius: float, homing_turn: float) -> void:
	if ROCKET_SCENE == null:
		return
	var rocket = ROCKET_SCENE.instantiate()
	rocket.global_position = spawn_pos
	rocket.damage = dmg
	if homing:
		rocket.homing = true
		rocket.homing_radius = homing_radius
		rocket.homing_turn = homing_turn
	get_tree().current_scene.add_child(rocket)


func _shoot_homing_salvo() -> void:
	if ROCKET_SCENE == null:
		return
	if roket_sound: roket_sound.play()
	var start_x: float = -((HOMING_SALVO_COUNT - 1) * HOMING_SALVO_SPACING) / 2.0
	for i in HOMING_SALVO_COUNT:
		var rocket = ROCKET_SCENE.instantiate()
		rocket.global_position = muzzle.global_position + Vector2(start_x + i * HOMING_SALVO_SPACING, 0)
		rocket.damage = HOMING_SALVO_DAMAGE
		get_tree().current_scene.add_child(rocket)


func try_activate_homing_salvo() -> bool:
	if current_weapon_module != "rocket_homing":
		return false
	if homing_salvo_cooldown > 0.0:
		return false
	homing_salvo_cooldown = HOMING_SALVO_COOLDOWN
	homing_salvo_used.emit()
	_shoot_homing_salvo()
	return true


func _spawn_laser_bullet(spawn_point: Node2D, dir: Vector2, dmg: int, pierce: bool = false) -> void:
	if spawn_point == null:
		return
	var bullet_scene = preload("res://entities/projectiles/PlayerBullet.tscn")
	if not bullet_scene:
		return
	var bullet = bullet_scene.instantiate()
	bullet.global_position = spawn_point.global_position
	bullet.damage = dmg
	bullet.direction = dir
	bullet.pierce = pierce
	get_tree().current_scene.add_child(bullet)


func _spawn_plasma_bullet() -> void:
	var bullet_scene = preload("res://entities/projectiles/PlayerBullet.tscn")
	if not bullet_scene:
		return
	var bullet = bullet_scene.instantiate()
	bullet.global_position = muzzle.global_position
	bullet.damage = LASER_PLASMA_DAMAGE
	bullet.direction = Vector2.UP
	bullet.homing = true
	bullet.homing_radius = LASER_PLASMA_HOMING_RADIUS
	bullet.homing_turn = LASER_PLASMA_HOMING_TURN
	bullet.modulate = Color(1.4, 0.9, 0.3, 1)
	bullet.scale = Vector2(1.2, 1.2)
	get_tree().current_scene.add_child(bullet)


func notify_plasma_hit() -> void:
	plasma_stack = min(25, plasma_stack + 1)
	plasma_reset_timer = LASER_PLASMA_STACK_RESET_TIME
	if plasma_stack >= 25:
		var sm := get_node_or_null("/root/SaveManager")
		if sm:
			sm.on_plasma_stack_reached_25()


func take_heal(amount: int) -> void:
	self.health = min(max_health, self.health + amount)
	health_changed.emit(health)
	var sm := get_node_or_null("/root/SaveManager")
	if sm:
		sm.tmp_health_packs_collected += amount
		if sm.tmp_health_packs_collected >= 35:
			sm.unlock_achievement("magnet")
	var flash := Node2D.new()
	flash.set_script(preload("res://entities/player/HealFlash.gd"))
	get_tree().current_scene.add_child(flash)
	flash.global_position = global_position


func take_damage(amount: int) -> void:
	if invulnerable:
		return

	if has_cocoon_shield and cocoon_shield_ready:
		cocoon_shield_ready = false
		cocoon_cd_timer.start()
		var sm := get_node_or_null("/root/SaveManager")
		if sm:
			sm.on_cocoon_shield_blocked()
		var flash_node := Node2D.new()
		flash_node.set_script(preload("res://entities/player/ShieldFlash.gd"))
		get_tree().current_scene.add_child(flash_node)
		flash_node.global_position = global_position
		flash_node.flash_color(0.2, Color(1.0, 0.85, 0.1), Color(1.0, 0.85, 0.1))
		if _cocoon_shield_instance and is_instance_valid(_cocoon_shield_instance):
			_cocoon_shield_instance.deactivate()
		shield_activated.emit()
		return

	if has_shield_module and shield_durability > 0:
		shield_durability -= amount
		if shield_durability <= 0:
			shield_durability = 0
			if _common_shield_instance and is_instance_valid(_common_shield_instance):
				_common_shield_instance.deactivate()
			_spawn_shield_flash()
			shield_activated.emit()
		else:
			_spawn_shield_flash()
		return

	if has_composite_armor:
		composite_hit_counter += 1
		if composite_hit_counter >= COMPOSITE_ARMOR_INTERVAL:
			composite_hit_counter = 0
			var flash_node := Node2D.new()
			flash_node.set_script(preload("res://entities/player/ShieldFlash.gd"))
			get_tree().current_scene.add_child(flash_node)
			flash_node.global_position = global_position
			flash_node.flash_color(0.2, Color(0.2, 0.9, 1.0), Color(0.3, 0.95, 1.0))
			return

	if has_diffusor and randf() < DIFFUSOR_CHANCE:
		var wave := preload("res://entities/effects/DiffusorWave.tscn").instantiate()
		get_tree().current_scene.add_child(wave)
		wave.global_position = global_position
		var main = get_tree().current_scene
		if main:
			var targets: Array[Node] = []
			for child in main.get_children():
				if child is CharacterBody2D and child != self and child.has_method("take_damage"):
					if global_position.distance_to(child.global_position) <= DIFFUSOR_RADIUS:
						targets.append(child)
			if targets.size() > 0:
				targets[randi() % targets.size()].take_damage(DIFFUSOR_DAMAGE)

	self.health -= amount
	health_changed.emit(health)

	if has_forsage:
		forsage_timer = FORSAGE_DURATION
		var sm := get_node_or_null("/root/SaveManager")
		if sm:
			sm.tmp_forsage_procs += 1
			if sm.tmp_forsage_procs >= 20:
				sm.unlock_achievement("forsage_user")

	if has_tactical_accelerator and not tactical_accel_active:
		tactical_accel_original_delay = shoot_delay
		tactical_accel_active = true
		tactical_accel_timer = TACTICAL_ACCEL_DURATION
		shoot_delay = shoot_delay * TACTICAL_ACCEL_FIRE_MULT
		var sm := get_node_or_null("/root/SaveManager")
		if sm:
			sm.tmp_tactical_accelerator_procs += 1
			if sm.tmp_tactical_accelerator_procs >= 20:
				sm.unlock_achievement("tactician")
	elif has_tactical_accelerator and tactical_accel_active:
		tactical_accel_timer = TACTICAL_ACCEL_DURATION
		var sm := get_node_or_null("/root/SaveManager")
		if sm:
			sm.tmp_tactical_accelerator_procs += 1
			if sm.tmp_tactical_accelerator_procs >= 20:
				sm.unlock_achievement("tactician")

	invulnerable = true
	collision_layer = 2
	collision_mask = 0
	_start_blinking()
	var main_s = get_tree().current_scene
	if main_s and main_s.has_method("shake_camera"):
		main_s.shake_camera(0.2, 5.0)
	
	var sm_main := get_node_or_null("/root/SaveManager")
	if sm_main:
		sm_main.on_player_damage_taken(current_weapon_module)
	
	if health <= 0:
		if has_cocoon_shield and not cocoon_revive_used:
			cocoon_revive_used = true
			health = ceil(float(max_health) * 0.5)
			health_changed.emit(health)
			invulnerable = false
			collision_layer = 3
			collision_mask = 1
			_stop_blinking()
			var revive_wave := preload("res://entities/effects/CocoonReviveWave.tscn").instantiate()
			get_tree().current_scene.add_child(revive_wave)
			revive_wave.global_position = global_position
			return
		die()
		return
	await get_tree().create_timer(INVULN_DURATION).timeout
	invulnerable = false
	collision_layer = 3
	collision_mask = 1
	_stop_blinking()


func _on_shield_recharged() -> void:
	shield_durability = SHIELD_MAX_DURABILITY


func _on_cocoon_ready() -> void:
	cocoon_shield_ready = true
	shield_recharged.emit()
	if _cocoon_shield_instance and is_instance_valid(_cocoon_shield_instance):
		_cocoon_shield_instance.is_goliath = is_goliath
		_cocoon_shield_instance.activate()


func _spawn_shield_flash() -> void:
	var flash := Node2D.new()
	flash.set_script(preload("res://entities/player/ShieldFlash.gd"))
	get_tree().current_scene.add_child(flash)
	flash.global_position = global_position
	flash.flash(0.2)


func revive_to_half() -> void:
	health = ceil(float(max_health) * 0.5)
	if health <= 0:
		health = 1
	invulnerable = false
	shooting_disabled = false
	collision_layer = 3
	collision_mask = 1
	_stop_blinking()
	var revive_wave := preload("res://entities/effects/CocoonReviveWave.tscn").instantiate()
	get_tree().current_scene.add_child(revive_wave)
	revive_wave.global_position = global_position
	health_changed.emit(health)


func die() -> void:
	player_died.emit()
	var main = get_tree().current_scene
	if main and main.has_method(&"game_over"):
		main.game_over()


func _start_blinking() -> void:
	var blink_target := _get_blink_target()
	if blink_tween:
		blink_tween.kill()
	blink_tween = create_tween()
	blink_tween.tween_property(blink_target, "modulate:a", 0.3, 0.1)
	blink_tween.tween_property(blink_target, "modulate:a", 1.0, 0.1)
	blink_tween.set_loops()


func _stop_blinking() -> void:
	var blink_target := _get_blink_target()
	blink_target.modulate.a = 1.0
	if blink_tween:
		blink_tween.kill()
		blink_tween = null


# ============================================================
# Goliath — рывок со щитом
# ============================================================

func try_start_goliath_charge() -> bool:
	if not is_goliath:
		return false
	if goliath_charge_active:
		return false
	if goliath_charge_cooldown > 0.0:
		return false
	goliath_charge_used.emit()
	_do_goliath_charge()
	return true


func _do_goliath_charge() -> void:
	goliath_charge_active = true
	goliath_charge_cooldown = GOLIATH_CHARGE_COOLDOWN

	if goliath_shield:
		goliath_shield.visible = true
		goliath_shield.play("default")

	if goliath_shield_area:
		goliath_shield_area.monitoring = true
		goliath_shield_area.monitorable = true

	invulnerable = true
	collision_layer = 2
	collision_mask = 0

	var main = get_tree().current_scene
	if main and main.has_method("shake_camera"):
		main.shake_camera(0.15, 8.0)

	var target_pos = global_position + Vector2.UP * GOLIATH_CHARGE_DISTANCE
	var vps = get_viewport_rect().size
	target_pos.x = clamp(target_pos.x, MARGIN, vps.x - MARGIN)
	target_pos.y = clamp(target_pos.y, MARGIN, vps.y - MARGIN)

	if goliath_charge_tween and goliath_charge_tween.is_valid():
		goliath_charge_tween.kill()
	goliath_charge_tween = create_tween()
	goliath_charge_tween.tween_property(self, "global_position", target_pos, GOLIATH_CHARGE_DURATION).set_trans(Tween.TRANS_LINEAR)
	goliath_charge_tween.tween_callback(_end_goliath_charge)


func _end_goliath_charge() -> void:
	goliath_charge_active = false

	if goliath_shield:
		goliath_shield.visible = false
		goliath_shield.stop()

	if goliath_shield_area:
		goliath_shield_area.monitoring = false
		goliath_shield_area.monitorable = false

	invulnerable = false
	collision_layer = 3
	collision_mask = 1


func _on_goliath_shield_body_entered(body: Node) -> void:
	if not goliath_charge_active:
		return
	if body == self:
		return
	if body is CharacterBody2D and body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(GOLIATH_CHARGE_DAMAGE)
		var sm := get_node_or_null("/root/SaveManager")
		if sm:
			sm.tmp_goliath_charge_kills += 1


func _on_goliath_shield_area_entered(area: Area2D) -> void:
	if not goliath_charge_active:
		return
	if area == self:
		return
	if area.is_in_group("enemy_bullet"):
		area.queue_free()


# ============================================================
# Бонусы скинов
# ============================================================

func _apply_skin_bonuses() -> void:
	var sm := get_node_or_null("/root/SaveManager")
	if sm == null:
		return
	
	var skin_idx: int = sm.get_current_skin(current_ship)
	var skin_module_id := "skin_%s_%d" % [current_ship, skin_idx]
	var module_path := "res://data/modules/%s.tres" % skin_module_id
	
	if not ResourceLoader.exists(module_path):
		return
	
	var module_data: Resource = load(module_path)
	if module_data == null:
		return
	
	if "damage_bonus" in module_data:
		bullet_damage += int(module_data.damage_bonus)
	
	if "speed_mult" in module_data:
		_skin_speed_mult = float(module_data.speed_mult)
	
	if "health_bonus" in module_data:
		var bonus := int(module_data.health_bonus)
		if bonus > 0:
			max_health += bonus
			health = min(health + bonus, max_health)
			health_changed.emit(health)
	
	if "fire_rate_mult" in module_data:
		var mult := float(module_data.fire_rate_mult)
		if mult > 0:
			shoot_delay *= mult