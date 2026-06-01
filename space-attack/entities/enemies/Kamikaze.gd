extends CharacterBody2D

const SPEED: float = 300.0

var health: int = 20
var time: float = 0.0


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	time += delta
	global_position.y += SPEED * delta
	global_position.x += sin(time * 4.0) * 30.0 * delta
	
	var vps = get_viewport_rect().size
	if global_position.y > vps.y + 50:
		queue_free()
	
	var player = get_tree().current_scene.get_node_or_null("Player")
	if player and not is_queued_for_deletion():
		if global_position.distance_to(player.global_position) < 20:
			if player.has_method("take_damage"):
				player.take_damage(1)
			queue_free()


func take_damage(amount: int) -> void:
	var tw = create_tween()
	tw.tween_property($InnerSprite, "modulate", Color.WHITE, 0.05)
	tw.tween_property($InnerSprite, "modulate", Color(1.0, 0.15, 0.15), 0.05)
	
	health -= amount
	if health <= 0:
		die()


func die() -> void:
	var main = get_tree().current_scene
	if main and main.has_method("add_score"):
		main.add_score(15)
	if main and main.has_method("add_credits"):
		main.add_credits(7)
	if main and main.has_method("_on_enemy_killed"):
		main._on_enemy_killed()
	
	var particles = CPUParticles2D.new()
	particles.amount = 10
	particles.lifetime = 0.3
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.color = Color.RED
	particles.global_position = global_position
	particles.emitting = true
	get_tree().current_scene.add_child(particles)
	get_tree().create_timer(1.0).timeout.connect(particles.queue_free)
	_spawn_death_circle()
	queue_free()


func _spawn_death_circle() -> void:
	var c := Node2D.new()
	c.global_position = global_position
	c.set_process(false)
	c.draw.connect(func():
		c.draw_circle(Vector2.ZERO, 16.0, Color.RED)
	)
	get_tree().current_scene.add_child(c)
	c.queue_redraw()
	get_tree().create_timer(0.3).timeout.connect(c.queue_free)
