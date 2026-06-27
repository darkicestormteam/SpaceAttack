extends Area2D

# Количество кадров в спрайтлисте asteroid_1.png
const FRAME_COUNT: int = 5

# Размер одного кадра (предполагаем квадратный спрайтлист 5x1)
const FRAME_WIDTH: int = 48
const FRAME_HEIGHT: int = 48

# Диапазоны случайной скорости (скорость фона ~800, астероиды +/- от неё)
const BASE_SPEED: float = 800.0
const SPEED_VARIANCE: float = 150.0

# Вращение
const ROTATION_SPEED_MIN: float = -1.5
const ROTATION_SPEED_MAX: float = 1.5

# Урон игроку при столкновении
const DAMAGE_TO_PLAYER: int = 1

var speed: float = 0.0
var rotation_speed: float = 0.0


func _ready() -> void:
	# Случайный кадр из 5
	$Sprite2D.frame = randi() % FRAME_COUNT
	
	# Случайная скорость
	speed = BASE_SPEED + randf_range(-SPEED_VARIANCE, SPEED_VARIANCE)
	
	# Случайное направление вращения
	rotation_speed = randf_range(ROTATION_SPEED_MIN, ROTATION_SPEED_MAX)
	
	# Настраиваем коллизию — прямоугольник примерно по размеру астероида
	var shape := RectangleShape2D.new()
	shape.size = Vector2(40, 40)
	$CollisionShape2D.shape = shape
	
	# Сигнал выхода за экран
	$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)
	
	# Сигнал столкновения с игроком
	body_entered.connect(_on_body_entered)
	
	add_to_group("asteroid")


func _process(delta: float) -> void:
	# Движение вниз
	position.y += speed * delta
	
	# Вращение
	rotation += rotation_speed * delta


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(DAMAGE_TO_PLAYER)
		queue_free()
