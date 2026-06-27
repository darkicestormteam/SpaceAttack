extends Area2D
class_name PlayerRocket

## Ракета игрока: летит вверх, наносит урон врагу при прямом попадании, спавнит взрыв.

@export var damage: int = 30
@export var speed: float = 500.0
## Скейл спрайта (в инспекторе можно подкрутить)
@export var sprite_scale: float = 3.0
## Направление движения (используется для ракет с фиксированным направлением,
## например залп Шторм). Если Vector2.ZERO — ракета летит вверх.
var direction: Vector2 = Vector2.ZERO
## Включает наведение на ближайшего врага (rocket_mk2 / rocket_homing).
var homing: bool = false
## Радиус поиска цели (px).
var homing_radius: float = 0.0
## Максимальная скорость поворота (рад/сек).
var homing_turn: float = 0.0
## Через сколько секунд после выстрела ракета начинает сворачивать к Vector2.UP.
## Используется в Шторме (rocket_nuke): ракеты летят веером, потом сходятся вверх.
## 0.0 = не сворачивать.
var straighten_after: float = 0.0
## Скорость сворачивания к Vector2.UP (рад/сек). Чем больше, тем быстрее сходятся.
var straighten_turn: float = 4.0

const EXPLOSION_SCENE: PackedScene = preload("res://entities/effects/Explosion.tscn")

var _hit: bool = false
var _velocity: Vector2 = Vector2.UP
var _time_alive: float = 0.0
const HOMING_MAX_LIFETIME: float = 2.5
var _current_dir: Vector2 = Vector2.UP


func _ready() -> void:
	add_to_group("bullet")
	add_to_group("player_bullet")
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

	# Стартовое направление: если задано через direction (Шторм) — используем его.
	_current_dir = direction if direction != Vector2.ZERO else Vector2.UP
	# На выход за viewport — тихо удаляемся
	get_tree().create_timer(0.05).timeout.connect(_check_bounds)


func _physics_process(delta: float) -> void:
	if _hit:
		return
	# Счётчик жизни ракеты — нужен и для наведения, и для сворачивания (Шторм).
	_time_alive += delta

	# Наведение (rocket_mk2 / rocket_homing): поворачиваем к ближайшему врагу
	if homing and homing_turn > 0.0 and homing_radius > 0.0:
		if _time_alive < HOMING_MAX_LIFETIME:
			var target: Node2D = _find_nearest_enemy()
			if target:
				var to_target: Vector2 = (target.global_position - global_position)
				if to_target.length() > 0.01:
					var desired: Vector2 = to_target.normalized()
					var max_step: float = homing_turn * delta
					_current_dir = _current_dir.rotated(_approach_angle(_current_dir, desired, max_step))
		else:
			homing = false  # вышло время — летим прямо

	# Сворачивание к Vector2.UP через straighten_after секунд (Шторм).
	# Используем ту же функцию _approach_angle, что и для наведения.
	if straighten_after > 0.0 and _time_alive >= straighten_after:
		var max_step_straight: float = straighten_turn * delta
		_current_dir = _current_dir.rotated(_approach_angle(_current_dir, Vector2.UP, max_step_straight))
		if _current_dir.dot(Vector2.UP) > 0.999:
			_current_dir = Vector2.UP  # защёлкнулись ровно вверх
	global_position += _current_dir * speed * delta
	# Поворачиваем Sprite так, чтобы нос указывал в направлении движения.
	# В сцене Sprite.rotation = 0 визуально означает нос вправо (в редакторе это выглядит
	# как нос вверх, потому что родительский PlayerRocket повёрнут и т.д.).
	# Эмпирически подобранное смещение: чтобы при полёте вверх нос смотрел вверх,
	# нужно повернуть Sprite на -PI/2 относительно _current_dir.angle().
	var sprite: AnimatedSprite2D = get_node_or_null("Sprite") as AnimatedSprite2D
	if sprite:
		sprite.rotation = _current_dir.angle() - PI / 2
	_check_bounds()


func _approach_angle(current: Vector2, desired: Vector2, max_step: float) -> float:
	# Возвращает угол (в радианах), на который нужно повернуть current к desired,
	# не превышая max_step. Положительный — против часовой.
	var cross: float = current.x * desired.y - current.y * desired.x
	var dot: float = current.x * desired.x + current.y * desired.y
	var signed_angle: float = atan2(cross, dot)
	if absf(signed_angle) <= max_step:
		return signed_angle
	return max_step if signed_angle > 0.0 else -max_step


func _find_nearest_enemy() -> Node2D:
	# Ищем ближайшего врага в радиусе наведения
	var best: Node2D = null
	var best_dist: float = homing_radius * homing_radius
	var tree := get_tree()
	if tree == null:
		return null
	for n in tree.get_nodes_in_group("enemy"):
		if not (n is Node2D):
			continue
		var d2: float = global_position.distance_squared_to((n as Node2D).global_position)
		if d2 < best_dist:
			best_dist = d2
			best = n as Node2D
	return best


func _check_bounds() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	# Ракета летит вверх — проверяем выход за верх или боковые края
	if global_position.y < -100 or global_position.x < -200 or global_position.x > viewport_size.x + 200:
		queue_free()


func _resolve_target(node: Node) -> Node:
	# Если нода сама имеет take_damage — бьём её.
	# Иначе (Area2D-хбокс вроде Carrier.BaseHitbox) — ищем родителя.
	if node == null:
		return null
	if node.has_method(&"take_damage"):
		return node
	var parent: Node = node.get_parent()
	if parent and parent.has_method(&"take_damage"):
		return parent
	return null


func _on_area_entered(area: Area2D) -> void:
	if _hit:
		return
	if area.is_in_group("player") or area.is_in_group("bullet"):
		return
	var target: Node = _resolve_target(area)
	if target and target.is_in_group("enemy"):
		_hit_enemy(target)


func _on_body_entered(body: Node2D) -> void:
	if _hit:
		return
	if body.is_in_group("player") or body.is_in_group("bullet"):
		return
	# Carrier — CharacterBody2D в группе carrier_body. Body-collision от ракеты (Area2D)
	# не сработает, но если сработает — найдём цель через _resolve_target.
	var target: Node = _resolve_target(body)
	if target and target.is_in_group("enemy"):
		_hit_enemy(target)


func _hit_enemy(target: Node) -> void:
	if _hit:
		return
	_hit = true
	if target and target.has_method(&"take_damage"):
		target.take_damage(damage)
	# Спавн эффекта взрыва в точке попадания
	if EXPLOSION_SCENE:
		var boom: Node2D = EXPLOSION_SCENE.instantiate()
		boom.global_position = global_position
		get_tree().current_scene.add_child(boom)
	queue_free()
