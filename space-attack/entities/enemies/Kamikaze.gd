extends CharacterBody2D

const SPEED: float = 300.0

var health: int = 20
var time: float = 0.0


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	time += delta
	global_position.y += SPEED * delta
	global_position.x += sin(time * 4.0) * 40.0 * delta
	
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
	tw.tween_property($Sprite2D, "modulate", Color.WHITE, 0.05)
	tw.tween_property($Sprite2D, "modulate", Color(1.0, 0.15, 0.15), 0.05)
	
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
	queue_free()
