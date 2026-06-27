extends Area2D

enum LaserType { MID, BIG }

## Тип лазера: MID = средний лазер, BIG = большой лазер
var laser_type: LaserType = LaserType.MID

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var big_laser_collision: CollisionShape2D = $BigLaser
@onready var mid_laser_collision: CollisionShape2D = $MidLaser2
@onready var mid_sprite: AnimatedSprite2D = $MidLaser
@onready var big_sprite: AnimatedSprite2D = $BigLaser2


func init(type: LaserType) -> void:
	laser_type = type


func _ready() -> void:
	# Добавляемся в группу вражеских снарядов для коллизий
	add_to_group("enemy_projectile")
	
	# Подключаем сигнал столкновения
	body_entered.connect(_on_body_entered)
	
	# Скрываем оба спрайта — анимация сама включит нужный
	mid_sprite.visible = false
	big_sprite.visible = false
	
	# Выбираем анимацию в зависимости от типа лазера
	# Коллизией полностью управляет AnimationPlayer (см. треки disabled)
	var anim_name: String
	match laser_type:
		LaserType.MID:
			mid_sprite.visible = true
			anim_name = "MidLaser"
			print("[EnemyLaser] MID laser")
		LaserType.BIG:
			big_sprite.visible = true
			anim_name = "BigLaser"
			print("[EnemyLaser] BIG laser")
	
	# Запускаем анимацию
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
		# Удаляемся после окончания анимации
		await animation_player.animation_finished
		queue_free()
	else:
		# Если анимации нет — удаляемся через 1 секунду
		await get_tree().create_timer(1.0).timeout
		queue_free()


func _on_body_entered(body: Node) -> void:
	# Игнорируем других врагов и пули
	if body.is_in_group("enemy") or body.is_in_group("bullet"):
		return
	# Наносим урон игроку при попадании
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(1)
