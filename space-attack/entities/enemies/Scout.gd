extends CharacterBody2D

const SPEED: float = 150.0

var health: int = 15

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	# Движение вниз
	global_position.y += SPEED * delta
	
	# Удаление при выходе за нижнюю границу
	var viewport_size = get_viewport_rect().size
	if global_position.y > viewport_size.y + 50:
		queue_free()
	
	# Столкновение с игроком (проверка дистанции)
	var player = get_tree().current_scene.get_node_or_null("Player")
	if player and not is_queued_for_deletion():
		if global_position.distance_to(player.global_position) < 28:
			if player.has_method(&"take_damage"):
				player.take_damage(1)
			queue_free()

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	var main = get_tree().current_scene
	if main and main.has_method(&"add_score"):
		main.add_score(10)
	if main and main.has_method(&"add_credits"):
		main.add_credits(5)
	if main and main.has_method(&"_on_enemy_killed"):
		main._on_enemy_killed()
	_spawn_death_particles()
	queue_free()


func _spawn_death_particles() -> void:
	var particles = CPUParticles2D.new()
	particles.amount = 8
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.color = Color.RED
	particles.global_position = global_position
	particles.emitting = true
	get_tree().current_scene.add_child(particles)
	get_tree().create_timer(1.0).timeout.connect(particles.queue_free)
