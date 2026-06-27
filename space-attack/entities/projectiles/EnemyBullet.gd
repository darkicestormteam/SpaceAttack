extends Area2D

const BASE_SPEED: float = 300.0
var direction: Vector2 = Vector2.DOWN
var from_scout: bool = false
var use_blue: bool = false
var speed: float = BASE_SPEED

@onready var sprite: AnimatedSprite2D = $Sprite2D


func _ready() -> void:
	speed = BASE_SPEED * Constants.projectile_speed_mult()
	add_to_group("bullet")
	add_to_group("enemy_bullet")
	body_entered.connect(_on_body_entered)
	if use_blue:
		sprite.animation = "Blue_Shot"
		sprite.play()


func _process(delta: float) -> void:
	global_position += direction * speed * delta
	
	var vps = get_viewport_rect().size
	if global_position.y < -50 or global_position.y > vps.y + 50:
		queue_free()
	if global_position.x < -50 or global_position.x > vps.x + 50:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy") or body.is_in_group("bullet"):
		return
	if from_scout and body.is_in_group("player") and body.get("is_goliath"):
		queue_free()
		return
	if body.has_method("take_damage") and body.is_in_group("player"):
		body.take_damage(1)
	queue_free()
