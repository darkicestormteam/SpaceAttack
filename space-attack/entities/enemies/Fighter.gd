extends Node2D

const SPEED: float = 100.0

var health: int = 40

@onready var shoot_timer: Timer = $ShootTimer
@onready var sprite: Sprite2D = $Sprite2D
@onready var muzzle: Marker2D = $Muzzle


func _ready() -> void:
	shoot_timer.timeout.connect(_shoot)
	shoot_timer.start()


func _process(delta: float) -> void:
	global_position.y += SPEED * delta
	
	var viewport_size = get_viewport_rect().size
	if global_position.y > viewport_size.y + 50:
		queue_free()
	
	var player = get_tree().current_scene.get_node_or_null("Player")
	if player and not is_queued_for_deletion():
		if global_position.distance_to(player.global_position) < 28:
			if player.has_method("take_damage"):
				player.take_damage(1)
			queue_free()


func _shoot() -> void:
	var player = get_tree().current_scene.get_node_or_null("Player")
	if not player or is_queued_for_deletion():
		return
	
	var bullet_scene = load("res://entities/projectiles/EnemyBullet.tscn")
	if bullet_scene:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = muzzle.global_position
		var dir = (player.global_position - global_position).normalized()
		bullet.direction = dir
		get_tree().current_scene.add_child(bullet)


func take_damage(amount: int) -> void:
	var tw = create_tween()
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.05)
	tw.tween_property(sprite, "modulate", Color(1.0, 0.5, 0.0), 0.05)
	
	health -= amount
	if health <= 0:
		die()


func die() -> void:
	var main = get_tree().current_scene
	if main and main.has_method("add_score"):
		main.add_score(20)
	if main and main.has_method("add_credits"):
		main.add_credits(10)
	if main and main.has_method("_on_enemy_killed"):
		main._on_enemy_killed()
	
	_spawn_death_particles()
	queue_free()


func _spawn_death_particles() -> void:
	var particles = CPUParticles2D.new()
	particles.amount = 10
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.color = Color.ORANGE_RED
	particles.global_position = global_position
	particles.emitting = true
	get_tree().current_scene.add_child(particles)
	get_tree().create_timer(1.0).timeout.connect(particles.queue_free)
