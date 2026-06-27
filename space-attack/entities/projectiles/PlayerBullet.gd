extends Area2D

const SPEED: float = 600.0
const HOMING_MAX_TURN: float = 4.0  # рад/сек по умолчанию, можно переопределить через homing_turn

var damage: int = 10
var direction: Vector2 = Vector2.UP
## Сквозной пробой — пуля не уничтожается при попадании во врага
var pierce: bool = false
## Самонаведение — пуля ищет ближайшего врага в радиусе и корректирует траекторию
var homing: bool = false
var homing_radius: float = 200.0
var homing_turn: float = HOMING_MAX_TURN

var _homing_recheck_timer: float = 0.0
const HOMING_RECHECK_INTERVAL: float = 0.1  # как часто ищем новую цель
var _homing_target: Node2D = null


func _ready() -> void:
	add_to_group("bullet")
	add_to_group("player_bullet")
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if homing:
		_update_homing(delta)
	global_position += direction.normalized() * SPEED * delta

	var viewport_size = get_viewport_rect().size
	if global_position.y < -50 or global_position.y > viewport_size.y + 50:
		queue_free()


func _update_homing(delta: float) -> void:
	_homing_recheck_timer -= delta
	if _homing_recheck_timer <= 0.0:
		_homing_recheck_timer = HOMING_RECHECK_INTERVAL
		_homing_target = _find_nearest_enemy()

	if _homing_target != null and is_instance_valid(_homing_target):
		var to_target: Vector2 = (_homing_target.global_position - global_position).normalized()
		var current_dir: Vector2 = direction.normalized()
		# Плавная коррекция траектории (не мгновенный поворот)
		var max_step: float = homing_turn * delta
		var new_dir: Vector2 = current_dir.lerp(to_target, clamp(max_step, 0.0, 1.0)).normalized()
		direction = new_dir
		# Поворачиваем спрайт в направлении полёта
		rotation = new_dir.angle() - PI / 2.0


func _find_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var nearest_dist: float = homing_radius
	var main := get_tree().current_scene
	if main == null:
		return null
	for child in main.get_children():
		if child is Node2D and child != self and child.is_in_group("enemy"):
			var d: float = global_position.distance_to(child.global_position)
			if d <= nearest_dist:
				nearest_dist = d
				nearest = child
	return nearest


func _on_area_entered(area: Area2D) -> void:
	# Игнорируем Area2D самого игрока
	if area.is_in_group("player"):
		return
	# Игнорируем другие пули
	if area.is_in_group("bullet"):
		return
	# Carrier броня (RightHitbox / LeftHitbox) — наносим урон
	if area.is_in_group("carrier_armor"):
		var carrier = area.get_parent()
		if carrier and carrier.has_method(&"take_damage"):
			carrier.take_damage(damage)
		_notify_hit()
		if not pierce:
			queue_free()
		return
	# Carrier база (BaseHitbox) — без урона, просто уничтожаем пулю
	if area.is_in_group("carrier_base"):
		queue_free()
		return
	if area.has_method(&"take_damage"):
		area.take_damage(damage)
	_notify_hit()
	if not pierce:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	# Игнорируем игрока
	if body.is_in_group("player"):
		return
	# Игнорируем Carrier — его обрабатывает area_entered
	if body.is_in_group("carrier_body"):
		return
	if body.has_method(&"take_damage"):
		body.take_damage(damage)
	_notify_hit()
	if not pierce:
		queue_free()


func _notify_hit() -> void:
	# Сообщаем Player-у о попадании плазмы для стека скорострельности
	if homing:
		var main := get_tree().current_scene
		if main:
			var player := main.get_node_or_null("Player")
			if player and player.has_method(&"notify_plasma_hit"):
				player.notify_plasma_hit()
