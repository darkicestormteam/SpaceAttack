extends Area2D

## Аптечка: двигается вниз, кружится в невесомости,
## при касании с игроком даёт +1 HP.

const FALL_SPEED: float = 80.0
const ROTATION_SPEED: float = 1.5   # радиан в секунду


func _ready() -> void:
	# Не участвуем в коллизиях, но детектим тела на слое 2 (pickup)
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	global_position.y += FALL_SPEED * delta
	rotation += ROTATION_SPEED * delta
	
	var vps = get_viewport_rect().size
	if global_position.y > vps.y + 50:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if not body.has_method("take_heal"):
		return
	if body.health >= body.max_health:
		return
	
	body.take_heal(1)
	queue_free()
