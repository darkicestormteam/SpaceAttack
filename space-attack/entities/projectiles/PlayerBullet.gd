extends Area2D

const SPEED: float = 600.0

var damage: int = 10
# Направление движения пули. По умолчанию — строго вверх (старое поведение).
# Чтобы пуля летела под углом, нужно задать это свойство до _ready/_process
# (например, сразу после instantiate в Player.gd).
var direction: Vector2 = Vector2.UP


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	# Движение в направлении direction
	global_position += direction.normalized() * SPEED * delta

	# Удаление при выходе за экран
	var viewport_size = get_viewport_rect().size
	if global_position.y < -50 or global_position.y > viewport_size.y + 50:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.has_method(&"take_damage"):
		area.take_damage(damage)
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method(&"take_damage"):
		body.take_damage(damage)
	queue_free()
