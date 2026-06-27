extends Node2D

## БЕГУНОК лазерной полосы препятствий.
## Спавнит LaserWallGenerator на позициях MarkerSpawn и MarkerSpawn2.
## Сам не двигается — генераторы сами летят вниз.

const LASER_GENERATOR_SCENE: PackedScene = preload("res://entities/obstacles/LaserWallGenerator.tscn")

# Минимальная скорость падения (стартовая)
@export var min_speed: float = 200.0

# Максимальная скорость падения (через 20 секунд)
@export var max_speed: float = 1000.0

# Время разгона от min до max (сек)
const ACCEL_TIME: float = 20.0

# CD между спавнами (сек)
const SPAWN_COOLDOWN: float = 1.0

# Зазор между концами лучей (пиксели) — базовый и для Goliath
const BEAM_GAP: float = 120.0
const BEAM_GAP_GOLIATH: float = 180.0

var spawn_timer: Timer = null
var _elapsed: float = 0.0


func _ready() -> void:
	spawn_timer = Timer.new()
	spawn_timer.name = "SpawnTimer"
	spawn_timer.wait_time = SPAWN_COOLDOWN
	spawn_timer.one_shot = false
	spawn_timer.autostart = true
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_spawn_pair)
	
	generator_speed = min_speed


## Останавливает спавн новых генераторов.
## Вызови перед тем как удалять Runner — существующие генераторы доживут своё и улетят вниз.
func stop_spawning() -> void:
	if spawn_timer:
		spawn_timer.stop()


func _process(delta: float) -> void:
	_elapsed += delta
	var t: float = clampf(_elapsed / ACCEL_TIME, 0.0, 1.0)
	var current_speed: float = lerpf(min_speed, max_speed, t)
	generator_speed = current_speed
	
	# Обновляем скорость у всех активных генераторов
	for gen in get_tree().get_nodes_in_group("laser_wall_generator"):
		gen.fall_speed = current_speed


# Скорость для новых спавнов
var generator_speed: float = 50.0



func _spawn_pair() -> void:
	var marker1: Marker2D = $MarkerSpawn
	var marker2: Marker2D = $MarkerSpawn2
	
	if not marker1 or not marker2:
		return
	
	# Проверяем, на каком корабле играет игрок (Goliath = больше зазор)
	var current_gap: float = BEAM_GAP
	var sm := get_node_or_null("/root/SaveManager")
	if sm and sm.current_ship == "goliath":
		current_gap = BEAM_GAP_GOLIATH
	
	var m1x: float = marker1.global_position.x  # 64
	var m2x: float = marker2.global_position.x  # 656
	var mid: float = (m1x + m2x) / 2.0  # 360
	
	# Случайно смещаем середину проёма (от -200 до +200)
	var gap_offset: float = randf_range(-200.0, 200.0)
	var gap_center: float = mid + gap_offset
	
	# Левый луч: от MarkerSpawn до gap_center - gap/2
	var left_len: float = max(20.0, gap_center - m1x - current_gap / 2.0)
	# Правый луч: от gap_center + gap/2 до MarkerSpawn2
	var right_len: float = max(20.0, m2x - gap_center - current_gap / 2.0)
	
	_spawn_generator(marker1, false, left_len)
	_spawn_generator(marker2, true, right_len)


func _spawn_generator(marker: Marker2D, mirror: bool = false, beam_len: float = 200.0) -> void:
	if LASER_GENERATOR_SCENE == null:
		return
	
	var gen = LASER_GENERATOR_SCENE.instantiate()
	gen.global_position = marker.global_position
	gen.fall_speed = generator_speed
	
	# Отзеркаливание по X
	if mirror:
		gen.scale.x = -1
	
	get_tree().current_scene.add_child(gen)
	gen.set_length(beam_len)
	gen.activate()
