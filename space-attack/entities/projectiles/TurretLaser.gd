extends Area2D

## Красный лазер турели. Летит в направлении direction, наносит урон игроку.

@export var speed: float = 500.0
@export var damage: int = 1


func _ready() -> void:
	add_to_group("enemy_projectile")
	add_to_group("enemy_bullet")
	add_to_group("bullet")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	global_position += Vector2.DOWN.rotated(global_rotation) * speed * delta
	
	# Удаляем за границами экрана
	var vps = get_viewport_rect().size
	if global_position.y > vps.y + 50 or global_position.y < -50 \
		or global_position.x < -50 or global_position.x > vps.x + 50:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy") or body.is_in_group("bullet"):
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy") or area.is_in_group("bullet"):
		return
	if area.is_in_group("player") and area.has_method("take_damage"):
		area.take_damage(damage)
		queue_free()