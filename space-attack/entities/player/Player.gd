extends CharacterBody2D

signal player_died
signal health_changed(new_health: int)

const SPEED: float = 400.0
const MARGIN: float = 20.0
const INVULN_DURATION: float = 1.0

var bullet_damage: int = 10
var shoot_delay: float = 0.2
var max_health: int = 3

@onready var muzzle: Marker2D = $Muzzle
@onready var sprite_2d: Sprite2D = $Sprite2D

var shoot_timer: float = 0.0
var health: int = 3
var invulnerable: bool = false
var blink_tween: Tween


func _ready() -> void:
	health_changed.emit(health)


func set_upgrades(damage_level: int, fire_rate_level: int, health_level: int) -> void:
	bullet_damage = 10 + damage_level * 5
	shoot_delay = max(0.05, 0.2 - fire_rate_level * 0.05)
	max_health = 3 + health_level
	health = max_health
	health_changed.emit(health)


func _process(_delta: float) -> void:
	shoot_timer += _delta
	if shoot_timer >= shoot_delay:
		shoot_timer = 0.0
		_shoot()


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
	if bullet_scene:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = muzzle.global_position
		bullet.damage = bullet_damage
		get_tree().current_scene.add_child(bullet)


func take_damage(amount: int) -> void:
	if invulnerable:
		return
	
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
