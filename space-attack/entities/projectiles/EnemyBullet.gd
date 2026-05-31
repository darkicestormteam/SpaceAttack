extends Area2D

const SPEED: float = 300.0
var direction: Vector2 = Vector2.DOWN


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	global_position += direction * SPEED * delta
	
	var vps = get_viewport_rect().size
	if global_position.y < -50 or global_position.y > vps.y + 50:
		queue_free()
	if global_position.x < -50 or global_position.x > vps.x + 50:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage") and body.is_in_group("player"):
		body.take_damage(1)
		queue_free()
