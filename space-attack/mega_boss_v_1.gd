extends CharacterBody2D

const SPEED: float = 10.0
const AMPLITUDE: float = 120.0
const MAX_HEALTH: int = 10000

# Интервалы между выстрелами в комбо
const COMBO_INNER_P1: float = 0.7
const COMBO_INNER_P2: float = 0.5
const COMBO_INNER_P3: float = 0.4

# Пауза между комбо
const COMBO_PAUSE_P1: float = 4.0
const COMBO_PAUSE_P2: float = 3.5
const COMBO_PAUSE_P3: float = 2.5

# Пороги фаз
const PHASE_2_THRESHOLD: float = 0.6  # 60%
const PHASE_3_THRESHOLD: float = 0.2  # 20%

enum Phase { ONE, TWO, THREE }

var health: int = MAX_HEALTH
var current_phase: Phase = Phase.ONE
var is_being_rammed: bool = false
var _start_x: float
var _base_y: float
var _time: float = 0.0
var _dying: bool = false
var _current_combo_index: int = 0
var _phase_y_shifted: bool = false
var _cd_reduction: float = 0.0

@onready var hitbox: Area2D = $Hitbox
@onready var mid_gun: Marker2D = $MidGun
@onready var left_gun: Marker2D = $LeftGun
@onready var left_gun2: Marker2D = $LeftGun2
@onready var right_gun: Marker2D = $RightGun
@onready var right_gun2: Marker2D = $RightGun2
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var _player_in_hitbox: Node = null
var _contact_damage_timer: Timer = null
var _combo_timer: Timer = null
const CONTACT_DAMAGE_INTERVAL: float = 0.2

# === Damage Flash ===
@export_group("Damage Flash")
@export var flash_color_bright: Color = Color(3, 3, 3, 1)
@export var flash_color_damage: Color = Color(1.5, 0.3, 0.3, 1)
@export_range(0.01, 0.5, 0.01) var flash_step_duration: float = 0.05
@export_range(1, 10, 1) var flash_cycles: int = 2


func _ready() -> void:
	add_to_group("enemy")
	_start_x = global_position.x
	_base_y = global_position.y
	queue_redraw()
	
	# Множители от сложности
	var enemy_hp_mul: float = Constants.enemy_hp_mult()
	var boss_hp_mul: float = Constants.boss_hp_mult()
	health = int(ceil(float(MAX_HEALTH) * enemy_hp_mul * boss_hp_mul))
	_cd_reduction = Constants.boss_cooldown_reduction()

	# Таймер периодического урона при контакте с игроком
	_contact_damage_timer = Timer.new()
	_contact_damage_timer.name = "ContactDamageTimer"
	_contact_damage_timer.wait_time = CONTACT_DAMAGE_INTERVAL
	_contact_damage_timer.one_shot = false
	_contact_damage_timer.autostart = false
	add_child(_contact_damage_timer)
	_contact_damage_timer.timeout.connect(_on_contact_damage_timer)

	# Обработчик столкновений с игроком через Area2D Hitbox
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)
		hitbox.body_exited.connect(_on_hitbox_body_exited)

	# Запускаем первое комбо через 2 секунды после появления
	_combo_timer = Timer.new()
	_combo_timer.name = "ComboTimer"
	_combo_timer.one_shot = true
	add_child(_combo_timer)
	_combo_timer.timeout.connect(_execute_next_attack)
	get_tree().create_timer(2.0).timeout.connect(_start_first_combo)


func _start_first_combo() -> void:
	_current_combo_index = 0
	_execute_next_attack()


# Возвращает список пушек для текущей атаки в зависимости от фазы
# Каждый элемент: [маркер, тип_лазера]
func _get_attack_patterns() -> Array[Array]:
	match current_phase:
		Phase.ONE:
			match _current_combo_index:
				0:  # Атака 1: MidGun → MidLaser
					return [[mid_gun, 0]]
				1:  # Атака 2: LeftGun + RightGun → MidLaser
					return [[left_gun, 0], [right_gun, 0]]
				2:  # Атака 3: MidGun + LeftGun + RightGun → MidLaser
					return [[mid_gun, 0], [left_gun, 0], [right_gun, 0]]
				_:
					return [[mid_gun, 0]]
		Phase.TWO:
			match _current_combo_index:
				0:  # Атака 1: MidGun → MidLaser + LeftGun2 + RightGun2 → BigLaser
					return [[mid_gun, 0], [left_gun2, 1], [right_gun2, 1]]
				1:  # Атака 2: LeftGun + RightGun → MidLaser
					return [[left_gun, 0], [right_gun, 0]]
				2:  # Атака 3: все 5 пушек
					return [[mid_gun, 0], [left_gun, 0], [left_gun2, 1], [right_gun, 0], [right_gun2, 1]]
				_:
					return [[mid_gun, 0]]
		Phase.THREE:
			match _current_combo_index:
				0:  # Атака 1: MidGun → BigLaser + LeftGun2 + RightGun2 → BigLaser
					return [[mid_gun, 1], [left_gun2, 1], [right_gun2, 1]]
				1:  # Атака 2: LeftGun + RightGun → MidLaser
					return [[left_gun, 0], [right_gun, 0]]
				2:  # Атака 3: все 5 пушек (MidGun → BigLaser)
					return [[mid_gun, 1], [left_gun, 0], [left_gun2, 1], [right_gun, 0], [right_gun2, 1]]
				_:
					return [[mid_gun, 1]]
	return [[mid_gun, 0]]


func _get_combo_inner_interval() -> float:
	var base: float
	match current_phase:
		Phase.ONE: base = COMBO_INNER_P1
		Phase.TWO: base = COMBO_INNER_P2
		Phase.THREE: base = COMBO_INNER_P3
		_: base = COMBO_INNER_P1
	return base * (1.0 - _cd_reduction)


func _get_combo_pause() -> float:
	var base: float
	match current_phase:
		Phase.ONE: base = COMBO_PAUSE_P1
		Phase.TWO: base = COMBO_PAUSE_P2
		Phase.THREE: base = COMBO_PAUSE_P3
		_: base = COMBO_PAUSE_P1
	return base * (1.0 - _cd_reduction)


func _execute_next_attack() -> void:
	if is_queued_for_deletion() or _dying:
		return
	
	var patterns = _get_attack_patterns()
	
	# Стреляем всеми пушками из паттерна с задержкой между выстрелами
	var inner_interval = _get_combo_inner_interval()
	for i in range(patterns.size()):
		var gun: Marker2D = patterns[i][0]
		var laser_type: int = patterns[i][1]
		if not gun:
			continue
		var delay = float(i) * inner_interval
		if delay <= 0.0:
			# Первый выстрел без задержки
			_spawn_laser(gun, laser_type, null)
		else:
			# Создаём таймер для задержки
			var delay_timer := Timer.new()
			delay_timer.name = "DelayTimer_" + str(i)
			delay_timer.wait_time = delay
			delay_timer.one_shot = true
			delay_timer.autostart = true
			delay_timer.timeout.connect(_spawn_laser.bind(gun, laser_type, delay_timer))
			add_child(delay_timer)
	
	# Переключаемся на следующую атаку в цикле (0→1→2→0→1→2...)
	_current_combo_index = (_current_combo_index + 1) % 3
	
	# Запускаем таймер для следующего комбо
	_combo_timer.wait_time = _get_combo_pause() + float(patterns.size()) * _get_combo_inner_interval()
	_combo_timer.start()


func _spawn_laser(gun: Marker2D, laser_type: int, delay_timer: Timer) -> void:
	# Очищаем таймер
	if delay_timer and is_instance_valid(delay_timer):
		delay_timer.queue_free()
	
	if is_queued_for_deletion() or _dying or not gun:
		return
	
	var laser_scene = preload("res://entities/projectiles/EnemyLaser.tscn")
	if not laser_scene:
		return
	var laser = laser_scene.instantiate()
	laser.init(laser_type)
	# Добавляем лазер как дочерний элемент маркера (пушки),
	# чтобы лазер следовал за движением босса автоматически.
	# Коллизия пуль игрока работает через группы, урон боссу не передаётся.
	gun.add_child(laser)
	laser.position = Vector2.ZERO
	laser.rotation = 0


func _check_phase_transition() -> void:
	var hp_ratio: float = float(health) / float(MAX_HEALTH)
	
	# Фаза 3: < 20%
	if hp_ratio <= PHASE_3_THRESHOLD and current_phase == Phase.TWO:
		current_phase = Phase.THREE
		print("[MegaBossV1] Phase 3 triggered! All lasers empowered.")
		_phase3_entrance()
		return
	
	# Фаза 2: < 60%
	if hp_ratio <= PHASE_2_THRESHOLD and current_phase == Phase.ONE:
		current_phase = Phase.TWO
		print("[MegaBossV1] Phase 2 triggered! Shifting down +50px, BigLasers online.")
		_phase2_entrance()


func _phase2_entrance() -> void:
	if _phase_y_shifted:
		return
	_phase_y_shifted = true
	
	# Отключаем синусоидальное движение на время анимации
	set_process(false)
	
	# Запоминаем целевую позицию (текущая + 50px вниз)
	var target_y: float = global_position.y + 50.0
	
	var vps = get_viewport_rect().size
	
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.set_ease(Tween.EASE_IN)
	
	# 1. Отлетает назад вверх за экран
	tw.tween_property(self, "global_position:y", -200.0, 0.6)
	# 2. Задержка за экраном 1 секунда
	tw.tween_interval(1.0)
	# 3. Резко влетает вниз как таран (на половину экрана)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "global_position:y", vps.y * 0.5, 0.4)
	# 4. Возвращается на свою позицию (текущая + 50)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "global_position:y", target_y, 0.5)
	# 5. Включаем обратно синусоидальное движение
	tw.tween_callback(func():
		set_process(true)
		_base_y = target_y
		_cancel_current_combo_and_restart()
	)


func _phase3_entrance() -> void:
	# Отключаем синусоидальное движение на время анимации
	set_process(false)
	
	var target_y: float = global_position.y
	var vps = get_viewport_rect().size
	
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.set_ease(Tween.EASE_IN)
	
	# 1. Отлетает назад вверх за экран
	tw.tween_property(self, "global_position:y", -200.0, 0.6)
	# 2. Задержка за экраном 1 секунда
	tw.tween_interval(1.0)
	# 3. Резко влетает вниз как таран (на половину экрана)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "global_position:y", vps.y * 0.5, 0.4)
	# 4. Возвращается на исходную позицию
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "global_position:y", target_y, 0.5)
	# 5. Включаем обратно синусоидальное движение
	tw.tween_callback(func():
		set_process(true)
		_cancel_current_combo_and_restart()
	)


func _cancel_current_combo_and_restart() -> void:
	# Останавливаем все активные delay-таймеры
	for child in get_children():
		if child is Timer and child.name.begins_with("DelayTimer"):
			child.queue_free()
	# Останавливаем таймер комбо
	if _combo_timer:
		_combo_timer.stop()
	# Перезапускаем комбо сначала
	_current_combo_index = 0
	get_tree().create_timer(1.0).timeout.connect(_execute_next_attack)


func _on_hitbox_body_exited(body: Node) -> void:
	if body == _player_in_hitbox:
		_player_in_hitbox = null
		if _contact_damage_timer:
			_contact_damage_timer.stop()


func _on_contact_damage_timer() -> void:
	if is_queued_for_deletion():
		if _contact_damage_timer:
			_contact_damage_timer.stop()
		return
	if not is_instance_valid(_player_in_hitbox):
		_player_in_hitbox = null
		if _contact_damage_timer:
			_contact_damage_timer.stop()
		return
	if not (_player_in_hitbox is CharacterBody2D):
		return
	if not _player_in_hitbox.is_in_group("player"):
		return
	if is_being_rammed:
		return
	# Симметричный обмен каждые 0.2 сек пока игрок в зоне
	if _player_in_hitbox.has_method("take_damage"):
		_player_in_hitbox.take_damage(1)
	if is_queued_for_deletion():
		if _contact_damage_timer:
			_contact_damage_timer.stop()
		return
	take_damage(30)
	if is_queued_for_deletion():
		if _contact_damage_timer:
			_contact_damage_timer.stop()


func _on_hitbox_body_entered(body: Node) -> void:
	if is_being_rammed or is_queued_for_deletion():
		return
	if body == self or not (body is CharacterBody2D):
		return
	if not body.is_in_group("player"):
		return
	if body.has_method("take_damage"):
		body.take_damage(1)
	if is_queued_for_deletion():
		return
	take_damage(30)
	if not is_queued_for_deletion():
		_player_in_hitbox = body
		if _contact_damage_timer and _contact_damage_timer.is_stopped():
			_contact_damage_timer.start()


func _process(delta: float) -> void:
	_time += delta
	global_position.x = _start_x + sin(_time * SPEED * 0.05) * AMPLITUDE


func take_damage(amount: int) -> void:
	_flash_damage()
	health -= amount
	_check_phase_transition()
	if health <= 0:
		die()


func _flash_damage() -> void:
	var tw := create_tween()
	for i in range(flash_cycles):
		tw.tween_property(self, "modulate", flash_color_bright, flash_step_duration)
		tw.tween_property(self, "modulate", flash_color_damage, flash_step_duration)
	tw.tween_property(self, "modulate", Color.WHITE, flash_step_duration)


func die() -> void:
	var main = get_tree().current_scene
	if main and main.has_method("add_score"):
		main.add_score(2000)
	if main and main.has_method("add_credits"):
		main.add_credits(600)
	if main and main.has_method("end_boss_fight"):
		main.end_boss_fight()

	if is_queued_for_deletion() or _dying:
		return
	_dying = true
	queue_redraw()

	set_physics_process(false)
	set_process(false)
	if hitbox:
		hitbox.set_deferred("monitoring", false)
		hitbox.set_deferred("monitorable", false)
	for child in get_children():
		if child is Timer and child.name in ["ContactDamageTimer", "ComboTimer"]:
			child.stop()
		if child is Timer and child.name.begins_with("DelayTimer"):
			child.queue_free()

	if animation_player and animation_player.has_animation("die"):
		print("[MegaBossV1] Playing die animation")
		if not animation_player.animation_finished.is_connected(_on_die_animation_finished):
			animation_player.animation_finished.connect(_on_die_animation_finished)
		animation_player.play("die")
		var anim_length: float = animation_player.current_animation_length
		if anim_length <= 0.0:
			anim_length = 1.5
		get_tree().create_timer(anim_length + 0.2).timeout.connect(_finish_die)
	else:
		print("[MegaBossV1] Die animation not found, instant death")
		queue_free()


func _on_die_animation_finished(anim_name: StringName) -> void:
	if anim_name != &"die":
		return
	print("[MegaBossV1] Die animation finished")
	if animation_player and animation_player.animation_finished.is_connected(_on_die_animation_finished):
		animation_player.animation_finished.disconnect(_on_die_animation_finished)
	_finish_die()


func _finish_die() -> void:
	if is_queued_for_deletion():
		return
	queue_free()
