extends Area2D
class_name PlayerPellet

## Дробинка дробовика: летит в указанном направлении, наносит урон при попадании, удаляется через max_distance.

@export var damage: int = 5
@export var speed: float = 550.0
@export var max_distance: float = 250.0

var direction: Vector2 = Vector2.UP
var _start_pos: Vector2
var rarity: String = "common"  # common | rare | epic | legendary
var pierce: bool = false  # Пробивает врагов (Epic Пробивной)
var _hit_bodies: Array = []  # Уже задетые враги (не наносим урон повторно)
var kartrich_burst: bool = false  # При убийстве врага — 6 pellet'ов из центра (Legendary)


func _ready() -> void:
	add_to_group("bullet")
	add_to_group("player_bullet")
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	_start_pos = global_position
	# Показываем нужный спрайт по rarity, скрываем остальные
	_apply_rarity_sprite()


func _apply_rarity_sprite() -> void:
	# Скрываем все спрайты, показываем нужный по rarity
	var sprite_map := {
		"common": "SpriteCommon",
		"rare": "SpriteRare",
		"epic": "SpriteEpic",
		"legendary": "SpriteLegend"
	}
	for child in get_children():
		if child is Sprite2D:
			child.visible = (child.name == sprite_map.get(rarity, "SpriteCommon"))


func _process(delta: float) -> void:
	global_position += direction.normalized() * speed * delta
	# Удаляем, если улетел дальше max_distance от точки спавна
	if global_position.distance_to(_start_pos) > max_distance:
		queue_free()
	# Удаляем при выходе за границы экрана (на всякий случай)
	var viewport_size: Vector2 = get_viewport_rect().size
	if global_position.y < -50 or global_position.y > viewport_size.y + 50 \
		or global_position.x < -50 or global_position.x > viewport_size.x + 50:
		queue_free()


func _resolve_target(node: Node) -> Node:
	if node == null:
		return null
	if node.has_method(&"take_damage"):
		return node
	var parent: Node = node.get_parent()
	if parent and parent.has_method(&"take_damage"):
		return parent
	return null


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player") or area.is_in_group("bullet"):
		return
	# Carrier база (BaseHitbox) — без урона, просто уничтожаем pellet
	if area.is_in_group("carrier_base"):
		queue_free()
		return
	# Carrier броня (RightHitbox / LeftHitbox) — наносим урон родителю (Carrier)
	if area.is_in_group("carrier_armor"):
		var carrier: Node = area.get_parent()
		if carrier and carrier.has_method(&"take_damage"):
			carrier.take_damage(damage)
		if not pierce:
			queue_free()
		return
	var target: Node = _resolve_target(area)
	if target and target.is_in_group("enemy"):
		_hit(target)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.is_in_group("bullet"):
		return
	# Carrier обрабатывается через area_entered (его Hitbox'ы — Area2D),
	# иначе pellet'ы будут наносить урон дважды.
	if body.is_in_group("carrier_body"):
		return
	var target: Node = _resolve_target(body)
	if target and target.is_in_group("enemy"):
		_hit(target)


func _hit(target: Node) -> void:
	if target == null or not target.has_method(&"take_damage"):
		return
	# Уже стреляли по этому врагу — пропускаем
	if target in _hit_bodies:
		return
	# Запоминаем health до урона, чтобы проверить смерть
	var old_health: int = target.get("health") if "health" in target else -1
	target.take_damage(damage)
	# Картечь (Legendary): при убийстве врага — 6 pellet'ов из центра
	if kartrich_burst and old_health > 0 and ("health" not in target or target.get("health") <= 0):
		call_deferred("_spawn_burst", global_position)
	if pierce:
		# Пробивной: pellet продолжает лететь, добавляем цель в список задетых
		_hit_bodies.append(target)
	else:
		queue_free()


const KARTRICH_BURST_COUNT: int = 6
const KARTRICH_BURST_DAMAGE: int = 5
const KARTRICH_BURST_SPEED: float = 550.0
const KARTRICH_BURST_MAX_DISTANCE: float = 300.0


func _spawn_burst(pos: Vector2) -> void:
	# При убийстве врага — 6 pellet'ов common вылетают из центра равномерно по 360°
	# Коллизия отключается на 0.2 сек, чтобы pellet'ы не зацепили тело умирающего врага
	var pellet_scene: PackedScene = preload("res://entities/projectiles/PlayerPellet.tscn")
	var angle_step: float = TAU / KARTRICH_BURST_COUNT
	for i in KARTRICH_BURST_COUNT:
		var angle: float = angle_step * i
		var dir := Vector2.from_angle(angle)
		var pellet = pellet_scene.instantiate()
		pellet.global_position = pos
		pellet.damage = KARTRICH_BURST_DAMAGE
		pellet.direction = dir
		pellet.speed = KARTRICH_BURST_SPEED
		pellet.max_distance = KARTRICH_BURST_MAX_DISTANCE
		pellet.rarity = "common"
		# Отключаем коллизию на 0.2 сек, чтобы pellet'ы улетели от тела врага
		pellet.set_deferred("monitoring", false)
		pellet.set_deferred("monitorable", false)
		get_tree().current_scene.add_child(pellet)
		var timer := Timer.new()
		timer.wait_time = 0.2
		timer.one_shot = true
		pellet.add_child(timer)
		timer.timeout.connect(func():
			if is_instance_valid(pellet):
				pellet.monitoring = true
				pellet.monitorable = true
		)
		timer.start()
