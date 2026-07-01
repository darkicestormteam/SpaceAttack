extends Button
class_name ModuleButton

## Универсальная кнопка модуля. Все визуальные параметры берёт из ModuleVisuals.
## Сцена: Button(root) + Background(AnimatedSprite2D) + IconAnimated(AnimatedSprite2D)
##        + IconRect(TextureRect) + RarityFrame(TextureRect) + FallbackLabel(Label)
## NOTE: `icon` зарезервировано Button'ом (текстура иконки) — поэтому child-нода
## и поле в скрипте называются icon_rect.
## NOTE: ноды резолвятся лениво через get_node (не @onready), чтобы можно было
## вызывать setup() сразу после instantiate() ДО попадания в дерево.

signal pressed_with_id(module_id: String)

const ModuleVisualsScript: Script = preload("res://data/visuals/ModuleVisuals.gd")

const DEFAULT_VISUALS_PATH: String = "res://data/visuals/default_module_visuals.tres"
const VISUALS_PATH_BY_ID: String = "res://data/visuals/{id}_visuals.tres"

const CONVENTION_ICON_PATH: String = "res://assets/sprites/ui/moduls/{id}.png"

var module_id: String = ""
var visuals: Resource = null  # ModuleVisuals

var _background: AnimatedSprite2D = null
var _icon_rect: TextureRect = null
var _icon_animated: AnimatedSprite2D = null
var _rarity_frame: TextureRect = null
var _fallback_label: Label = null
var _skin_preview: Node2D = null
var _skin_instance: Node2D = null
var _ready_done: bool = false


func _ready() -> void:
	_background = get_node_or_null("Background") as AnimatedSprite2D
	_icon_rect = get_node_or_null("IconRect") as TextureRect
	_icon_animated = get_node_or_null("IconAnimated") as AnimatedSprite2D
	_rarity_frame = get_node_or_null("RarityFrame") as TextureRect
	_fallback_label = get_node_or_null("FallbackLabel") as Label
	_skin_preview = get_node_or_null("SkinPreview") as Node2D
	_ready_done = true

	pressed.connect(_on_pressed)
	mouse_entered.connect(_refresh_visual_state)
	mouse_exited.connect(_refresh_visual_state)
	button_down.connect(_refresh_visual_state)
	button_up.connect(_refresh_visual_state)

	# Если setup был вызван до попадания в дерево — применим сейчас.
	if not visuals == null or module_id != "":
		_apply_visuals()


## Инициализация по id. Сам подтянет visuals и иконку.
## Можно вызывать как ДО, так и ПОСЛЕ add_child в дерево.
func setup(p_module_id: String, p_visuals: Resource = null) -> void:
	module_id = p_module_id
	visuals = p_visuals if p_visuals != null else _load_visuals(p_module_id)
	# Если нода уже в дереве — _ready отработал, можно применить.
	# Если нет — _ready вызовет _apply_visuals сам.
	if _ready_done:
		_apply_visuals()


func _on_pressed() -> void:
	pressed_with_id.emit(module_id)


func _load_visuals(p_module_id: String) -> Resource:
	var path: String = VISUALS_PATH_BY_ID.replace("{id}", p_module_id)
	if ResourceLoader.exists(path):
		var res: Resource = load(path)
		if res != null:
			return res
	if ResourceLoader.exists(DEFAULT_VISUALS_PATH):
		return load(DEFAULT_VISUALS_PATH)
	return null


func _resolve_icon_texture(p_visuals: Resource) -> Texture2D:
	if p_visuals == null:
		return null
	if "icon_texture" in p_visuals and p_visuals.icon_texture != null:
		return p_visuals.icon_texture
	var convention: String = CONVENTION_ICON_PATH
	if "icon_path_convention" in p_visuals and not str(p_visuals.icon_path_convention).is_empty():
		convention = str(p_visuals.icon_path_convention)
	var candidate: String = convention.replace("{id}", module_id)
	if ResourceLoader.exists(candidate):
		return load(candidate) as Texture2D
	return null


func _apply_visuals() -> void:
	if not _ready_done:
		return
	if visuals == null:
		custom_minimum_size = Vector2(64, 64)
		if _icon_rect:
			_icon_rect.visible = false
		if _icon_animated:
			_icon_animated.visible = false
			_icon_animated.stop()
		if _fallback_label:
			_fallback_label.text = module_id.substr(0, 1).to_upper() if not module_id.is_empty() else ""
		return

	if "button_size" in visuals:
		custom_minimum_size = visuals.button_size

	# background
	if _background != null:
		if "background_frames" in visuals and visuals.background_frames != null:
			_background.sprite_frames = visuals.background_frames
			_background.speed_scale = float(visuals.background_speed) if "background_speed" in visuals else 1.0
			_background.offset = visuals.background_offset if "background_offset" in visuals else Vector2.ZERO
			_background.visible = true
			_background.play("default")
		else:
			_background.visible = false
			_background.stop()

	# icon: сначала пробуем анимированную (SpriteFrames), иначе — статическую текстуру
	var animated_frames: SpriteFrames = null
	if "icon_animated_frames" in visuals:
		animated_frames = visuals.icon_animated_frames

	var used_animated: bool = false
	if animated_frames != null and _icon_animated != null:
		_icon_animated.sprite_frames = animated_frames
		_icon_animated.scale = Vector2(visuals.icon_scale, visuals.icon_scale) if "icon_scale" in visuals else Vector2.ONE
		_icon_animated.position = visuals.icon_offset if "icon_offset" in visuals else Vector2.ZERO
		_icon_animated.speed_scale = float(visuals.icon_animated_speed) if "icon_animated_speed" in visuals else 1.0
		_icon_animated.visible = true
		var anim_name: String = str(visuals.icon_animated_name) if "icon_animated_name" in visuals and not str(visuals.icon_animated_name).is_empty() else "default"
		if _icon_animated.sprite_frames.has_animation(anim_name):
			_icon_animated.play(anim_name)
		else:
			_icon_animated.play()
		used_animated = true

	if _icon_animated != null and not used_animated:
		_icon_animated.visible = false
		_icon_animated.stop()

	var icon_tex: Texture2D = null if used_animated else _resolve_icon_texture(visuals)
	if icon_tex != null and _icon_rect != null:
		_icon_rect.texture = icon_tex
		_icon_rect.scale = Vector2(visuals.icon_scale, visuals.icon_scale) if "icon_scale" in visuals else Vector2.ONE
		_icon_rect.position = visuals.icon_offset if "icon_offset" in visuals else Vector2.ZERO
		_icon_rect.visible = true
		if _fallback_label:
			_fallback_label.visible = false
	else:
		if _icon_rect and not used_animated:
			_icon_rect.visible = false
		if _fallback_label and not used_animated:
			_fallback_label.visible = true
			_fallback_label.text = str(visuals.fallback_text) if "fallback_text" in visuals else ""
			if _fallback_label.text.is_empty() and not module_id.is_empty():
				_fallback_label.text = module_id.substr(0, 1).to_upper()

	# rarity frame
	if _rarity_frame != null:
		if "rarity_frame" in visuals and visuals.rarity_frame != null:
			_rarity_frame.texture = visuals.rarity_frame
			_rarity_frame.modulate = visuals.rarity_color if "rarity_color" in visuals else Color.WHITE
			_rarity_frame.visible = true
		else:
			_rarity_frame.visible = false

	# skin scene: если есть skin_scene — инстанциируем её в SkinPreview
	if _skin_preview != null:
		# Удаляем старый инстанс
		if _skin_instance:
			_skin_instance.queue_free()
			_skin_instance = null
		
		_skin_preview.visible = false
		if "skin_scene" in visuals and visuals.skin_scene != null:
			var scene: PackedScene = visuals.skin_scene
			var inst: Node = scene.instantiate()
			if inst != null:
				_skin_instance = inst
				_skin_preview.add_child(inst)
				_skin_preview.visible = true
				# Отключаем ввод на всех нодах инстанса
				_ignore_input_recursive(inst)

	_refresh_visual_state()


func _ignore_input_recursive(node: Node) -> void:
	if node is Area2D:
		node.monitoring = false
		node.monitorable = false
	if node is CollisionObject2D:
		node.collision_layer = 0
		node.collision_mask = 0
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_input_recursive(child)


func _refresh_visual_state() -> void:
	if visuals == null:
		modulate = Color.WHITE
		return
	var c: Color = Color.WHITE
	if disabled:
		c = visuals.disabled_color if "disabled_color" in visuals else Color(0.6, 0.6, 0.6, 0.8)
	elif button_pressed:
		c = visuals.pressed_color if "pressed_color" in visuals else Color(0.85, 0.85, 0.85, 1)
	elif is_hovered():
		c = visuals.hover_color if "hover_color" in visuals else Color(1.15, 1.15, 1.15, 1)
	else:
		c = visuals.normal_color if "normal_color" in visuals else Color.WHITE
	modulate = c
