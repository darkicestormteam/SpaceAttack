extends Area2D

## Генератор лазерной стены.

const DAMAGE_TO_PLAYER: int = 1
const CHARGE_DURATION: float = 0.5

## Скорость падения вниз (пикселей/сек)
var fall_speed: float = 50.0

## Активен ли луч (наносит урон)
var is_active: bool = false

## Длина луча в пикселях
var beam_length: float = 200.0

## Амплитуда покачивания по X (пиксели)
const SWAY_AMPLITUDE: float = 5.0

## Скорость покачивания
const SWAY_SPEED: float = 1.5

# Начальная фаза (случайная)
var _sway_phase: float = 0.0
var _base_x: float = 0.0

var generator_sprite: AnimatedSprite2D = null
var beam: Area2D = null
var laser_sprite: AnimatedSprite2D = null
var beam_collision: CollisionShape2D = null


func _ready() -> void:
	_sway_phase = randf_range(0.0, TAU)
	_base_x = position.x
	
	generator_sprite = $GeneratorSprite
	beam = $Beam
	laser_sprite = $Beam/LaserSprite
	beam_collision = $Beam/CollisionShape2D
	
	add_to_group("laser_wall_generator")
	
	body_entered.connect(_on_body_entered_generator)
	
	if beam:
		beam.body_entered.connect(_on_beam_body_entered)
	
	# Удаление при выходе за экран
	var notifier := VisibleOnScreenNotifier2D.new()
	notifier.name = "ScreenNotifier"
	notifier.screen_exited.connect(queue_free)
	add_child(notifier)
	
	_update_beam()


func _process(delta: float) -> void:
	position.y += fall_speed * delta
	
	var elapsed: float = Time.get_ticks_msec() / 1000.0
	position.x = _base_x + sin(elapsed * SWAY_SPEED + _sway_phase) * SWAY_AMPLITUDE


func set_length(length: float) -> void:
	beam_length = length
	_update_beam()


func _update_beam() -> void:
	if laser_sprite == null or beam_collision == null:
		return
	
	# Базовая ширина обрезанного кадра 10px
	# (в атласе обрезано по 3px слева и справа от 16px)
	var base_width: float = 10.0
	
	# Масштаб по X под нужную длину
	var scale_x: float = beam_length / base_width
	laser_sprite.scale.x = scale_x
	laser_sprite.position.x = 0.0
	
	# Коллизия под размер луча
	var shape := RectangleShape2D.new()
	shape.size = Vector2(beam_length, 20.0)
	beam_collision.shape = shape
	beam_collision.position.x = beam_length / 2.0
	
	# Если не активны — отключаем мониторинг
	if not is_active:
		if beam:
			beam.monitoring = false
			beam.monitorable = false


func activate() -> void:
	if is_active:
		return
	
	# У анимации один стейт default, charge не существует
	
	var tween := create_tween()
	tween.set_parallel(true)
	
	if laser_sprite:
		var target_scale_x: float = beam_length / 10.0
		laser_sprite.scale.x = 0.0
		tween.tween_property(laser_sprite, "scale:x", target_scale_x, CHARGE_DURATION).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	
	is_active = true
	
	
	if beam:
		beam.monitoring = true
		beam.monitorable = true


func _on_beam_body_entered(body: Node) -> void:
	if not is_active:
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(DAMAGE_TO_PLAYER)


func _on_body_entered_generator(body: Node) -> void:
	pass
