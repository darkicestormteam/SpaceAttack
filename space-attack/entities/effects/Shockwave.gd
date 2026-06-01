extends Area2D

# Эффект "Импульсная волна" (Shockwave). Активная способность:
# при вызове создаёт Area2D радиусом 200 px, наносит урон врагам и уничтожает
# вражеские снаряды. Существует DURATION секунд.

const RADIUS: float = 200.0
const DURATION: float = 0.2
const DAMAGE: int = 20

# Путь сцены пули игрока — чтобы не уничтожать свои снаряды.
const PLAYER_BULLET_PATH: String = "res://entities/projectiles/PlayerBullet.tscn"

# Путь сцены игрока — чтобы шок-волна не била own носителя.
const PLAYER_SCENE_PATH: String = "res://entities/player/Player.tscn"

var _visuals: Node2D


func _ready() -> void:
	# Визуальная часть — отдельный Node2D, чтобы рисовать в _draw и
	# легко масштабировать.
	_visuals = Node2D.new()
	_visuals.name = "Visuals"
	add_child(_visuals)
	_visuals.set_script(preload("res://entities/effects/ShockwaveVisuals.gd"))

	# CollisionShape2D из .tscn имеет radius=200. Чтобы анимировать расширение,
	# уменьшим CircleShape2D.radius до маленького, а затем анимируем обратно.
	# НО! tween на circle.radius не вызывает пересчёт collision в Godot 4.
	# Решение: используем scale родителя (Area2D) — scale 0.001 → 1.0 расширяет
	# визуальный круг и CollisionShape одновременно.
	scale = Vector2(0.001, 0.001)
	_visuals.scale = Vector2(0.001, 0.001)
	# Визуал рисует круг радиуса 1, scale родителя увеличит его до 1, scale visuals
	# масштабирует визуал внутри. Чтобы получить радиус RADIUS визуально:
	# visuals.scale * Area2D.scale = RADIUS. Если Area2D.scale=1, visuals.scale=RADIUS.

	# Анимация: scale Area2D 0.001 → 1.0 за DURATION
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1, 1), DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_visuals, "scale", Vector2(RADIUS, RADIUS), DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_visuals, "modulate:a", 0.0, DURATION).set_trans(Tween.TRANS_LINEAR)

	monitoring = true
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

	# Авто-удаление через DURATION
	await get_tree().create_timer(DURATION).timeout
	queue_free()


func _on_area_entered(area: Node) -> void:
	_handle_hit(area)


func _on_body_entered(body: Node) -> void:
	_handle_hit(body)


func _handle_hit(target: Node) -> void:
	if target == self:
		return

	# Не бьём своего носителя (игрок) и свои пули
	if "scene_file_path" in target:
		if target.scene_file_path == PLAYER_BULLET_PATH:
			return
		if target.scene_file_path == PLAYER_SCENE_PATH:
			return

	# Враг — CharacterBody2D (или PhysicsBody2D) с методом take_damage
	if target is PhysicsBody2D and target.has_method("take_damage"):
		target.take_damage(DAMAGE)
		return

	# Вражеский снаряд — любой Area2D (но не свои)
	if target is Area2D:
		target.queue_free()
