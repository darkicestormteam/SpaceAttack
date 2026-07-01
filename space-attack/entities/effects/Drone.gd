extends Node2D

## Дрон, кружащийся вокруг родителя (игрока).

const ORBIT_RADIUS: float = 60.0
const ORBIT_SPEED: float = 2.0
const WOBBLE_AMPLITUDE: float = 5.0
const WOBBLE_SPEED: float = 4.0
const SHOOT_INTERVAL_BASE: float = 1.0
const FIRE_RATE_MULT: float = 4.0

## Копировать оружие игрока?
var copy_weapon: bool = false
## Ловить снаряды?
var catch_projectiles: bool = false
## ID модуля оружия для копирования (задаётся из Player.gd)
var weapon_module_id: String = ""

var _angle: float = 0.0
var _shoot_timer: float = 0.0
var _random_offset: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var muzzle: Marker2D = $Muzzle


func _ready() -> void:
	_random_offset = randf_range(0.0, TAU)
	_shoot_timer = randf_range(0.0, 1.0)
	if has_meta("orbit_offset"):
		_angle = get_meta("orbit_offset")
	if catch_projectiles:
		_add_collision_area()


func _add_collision_area() -> void:
	var area := Area2D.new()
	area.name = "CatchArea"
	area.collision_layer = 0
	area.collision_mask = 1  # слой 1 — вражеские пули (Area2D)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 12.0
	shape.shape = circle
	area.add_child(shape)
	add_child(area)
	area.area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	# Уничтожаем только вражеские пули, не трогаем свои
	if area.is_in_group("bullet") and not area.is_in_group("player_bullet"):
		area.queue_free()
	if sprite:
		var tw := create_tween()
		tw.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.05)
		tw.tween_property(sprite, "modulate", Color(0, 0.8, 1, 1), 0.1)


func _process(delta: float) -> void:
	if not is_instance_valid(get_parent()):
		return
	_angle += ORBIT_SPEED * delta
	var base_x = cos(_angle) * ORBIT_RADIUS
	var base_y = sin(_angle) * ORBIT_RADIUS
	var wobble = sin(_angle * WOBBLE_SPEED + _random_offset) * WOBBLE_AMPLITUDE
	position = Vector2(base_x + wobble, base_y + wobble * 0.5)
	
	var interval = SHOOT_INTERVAL_BASE
	if copy_weapon:
		var parent = get_parent()
		if parent and "shoot_delay" in parent:
			interval = parent.shoot_delay * FIRE_RATE_MULT
		else:
			interval = SHOOT_INTERVAL_BASE * FIRE_RATE_MULT
	
	_shoot_timer += delta
	if _shoot_timer >= interval:
		_shoot_timer = 0.0
		# Проверка: если у родителя (Player) стрельба заблокирована — дрон не стреляет
		var parent = get_parent()
		if parent and "shooting_disabled" in parent and parent.shooting_disabled:
			return
		_shoot()


func _shoot() -> void:
	var spawn_pos = muzzle.global_position if muzzle else global_position
	
	if copy_weapon and not weapon_module_id.is_empty():
		_spawn_copied_weapon(spawn_pos)
	else:
		_spawn_basic_laser(spawn_pos)


func _spawn_basic_laser(spawn_pos: Vector2) -> void:
	var bullet_scene = preload("res://entities/projectiles/PlayerBullet.tscn")
	if not bullet_scene:
		return
	var bullet = bullet_scene.instantiate()
	bullet.global_position = spawn_pos
	bullet.damage = 5
	bullet.direction = Vector2.UP
	get_tree().current_scene.add_child(bullet)


func _spawn_copied_weapon(spawn_pos: Vector2) -> void:
	var parent = get_parent()
	if not parent or not parent.has_method("get_weapon_module_id"):
		_spawn_basic_laser(spawn_pos)
		return
	
	var mod_id = parent.get_weapon_module_id()
	
	# Ракеты
	if mod_id in ["rocket", "rocket_mk2", "rocket_homing", "rocket_nuke"]:
		var rocket_scene = preload("res://entities/projectiles/PlayerRocket.tscn")
		if not rocket_scene:
			_spawn_basic_laser(spawn_pos)
			return
		var rocket = rocket_scene.instantiate()
		rocket.global_position = spawn_pos
		rocket.damage = parent.bullet_damage if "bullet_damage" in parent else 10
		rocket.direction = Vector2.UP
		get_tree().current_scene.add_child(rocket)
		return
	
	# Дробь (pellet)
	if mod_id in ["shotgun", "shotgun_whistle", "shotgun_pressure", "shotgun_heavy"]:
		var pellet_scene = preload("res://entities/projectiles/PlayerPellet.tscn")
		if not pellet_scene:
			_spawn_basic_laser(spawn_pos)
			return
		# 4 pellet-дробинки веером
		var spread: float = 0.2  # ~11.5° полу-разброс
		for i in range(4):
			var pellet = pellet_scene.instantiate()
			pellet.global_position = spawn_pos
			pellet.damage = parent.bullet_damage if "bullet_damage" in parent else 5
			pellet.direction = Vector2.UP.rotated(randf_range(-spread, spread))
			get_tree().current_scene.add_child(pellet)
		return
	
	# Лазеры и всё остальное — PlayerBullet
	var bullet_scene = preload("res://entities/projectiles/PlayerBullet.tscn")
	if not bullet_scene:
		return
	var bullet = bullet_scene.instantiate()
	bullet.global_position = spawn_pos
	bullet.damage = parent.bullet_damage if "bullet_damage" in parent else 10
	bullet.direction = Vector2.UP
	get_tree().current_scene.add_child(bullet)
