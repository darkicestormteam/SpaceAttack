extends CanvasLayer

signal popup_closed
signal opened_again_requested

const CHEST_SCENE: PackedScene = preload("res://entities/items/Chest.tscn")
const MODULE_BUTTON_SCENE: PackedScene = preload("res://ui/popups/ModuleButton.tscn")

const RARITY_COLORS: Dictionary = {
	"common": Color("#ffffff"),
	"rare": Color("#4d9aff"),
	"epic": Color("#9b4dff"),
	"legendary": Color("#ffb31a")
}

const RARITY_NAMES: Dictionary = {
	"common": "Обычный",
	"rare": "Редкий",
	"epic": "Эпический",
	"legendary": "Легендарный"
}

const MODULE_PATHS: Dictionary = {
	"laser": "res://data/modules/Laser_Common.tres",
	"laser_mk2": "res://data/modules/Laser_MkII.tres",
	"laser_pierce": "res://data/modules/Laser_Pierce.tres",
	"laser_plasma": "res://data/modules/Laser_Plasma.tres",
	"shotgun": "res://data/modules/shotgun.tres",
	"shotgun_whistle": "res://data/modules/shotgun_whistle.tres",
	"shotgun_pressure": "res://data/modules/shotgun_pressure.tres",
	"shotgun_heavy": "res://data/modules/shotgun_heavy.tres",
	"rocket": "res://data/modules/rocket.tres",
	"rocket_mk2": "res://data/modules/rocket_mk2.tres",
	"rocket_homing": "res://data/modules/rocket_homing.tres",
	"rocket_nuke": "res://data/modules/rocket_nuke.tres",
	"light_armor": "res://data/modules/light_armor.tres",
	"shield": "res://data/modules/shield_new.tres",
	"composite_armor": "res://data/modules/composite_armor.tres",
	"forsage": "res://data/modules/forsage.tres",
	"tactical_accelerator": "res://data/modules/tactical_accelerator.tres",
	"diffusor": "res://data/modules/diffusor.tres",
	"cocoon_shield": "res://data/modules/cocoon_shield.tres",
	"drone": "res://data/modules/drone.tres",
	"drone_rare": "res://data/modules/drone_rare.tres",
	"drone_epic": "res://data/modules/drone_epic.tres",
	"drone_legendary": "res://data/modules/drone_legendary.tres",
	"shockwave": "res://data/modules/shockwave.tres",
	"turbo": "res://data/modules/turbo.tres",
	"nanobots": "res://data/modules/nanobots.tres",
	"skin_vanguard_0": "res://data/modules/skin_vanguard_0.tres",
	"skin_vanguard_1": "res://data/modules/skin_vanguard_1.tres",
	"skin_vanguard_2": "res://data/modules/skin_vanguard_2.tres",
	"skin_phantom_0": "res://data/modules/skin_phantom_0.tres",
	"skin_phantom_1": "res://data/modules/skin_phantom_1.tres",
	"skin_phantom_2": "res://data/modules/skin_phantom_2.tres",
	"skin_goliath_0": "res://data/modules/skin_goliath_0.tres",
	"skin_goliath_1": "res://data/modules/skin_goliath_1.tres",
	"skin_goliath_2": "res://data/modules/skin_goliath_2.tres"
}

var _module_id: String = ""
var _module_name: String = ""
var _module_rarity: String = "common"
var _is_duplicate: bool = false
var _obtained_count: int = 0
var _total_count: int = 0

@onready var dim: ColorRect = %Dim
@onready var panel: Panel = %Panel
@onready var module_btn_holder: Control = %ModuleBtnHolder
@onready var name_label: Label = %NameLabel
@onready var rarity_label: Label = %RarityLabel
@onready var duplicate_label: Label = %DuplicateLabel
@onready var progress_label: Label = %ProgressLabel
@onready var accept_btn: Button = %AcceptBtn
@onready var again_btn: Button = %AgainBtn


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	dim.visible = false
	panel.visible = false
	duplicate_label.visible = false
	accept_btn.pressed.connect(_on_accept_pressed)
	again_btn.pressed.connect(_on_again_pressed)


func _input(event: InputEvent) -> void:
	# Блокируем клики снаружи Panel, но разрешаем внутри (кнопки работают)
	if event is InputEventMouseButton and event.pressed and panel.visible:
		var mb: InputEventMouseButton = event
		var panel_rect: Rect2 = panel.get_global_rect()
		if not panel_rect.has_point(mb.position):
			get_viewport().set_input_as_handled()


func setup(module_id: String, is_new: bool, compensation: int, obtained_count: int = 0, total_count: int = 0) -> void:
	_module_id = module_id
	_is_duplicate = not is_new
	_obtained_count = obtained_count
	_total_count = total_count

	var mod: Resource = _load_module(module_id)
	if mod != null:
		if "name" in mod:
			_module_name = str(mod.name)
		if "rarity" in mod:
			_module_rarity = str(mod.rarity)
	if _module_name.is_empty():
		_module_name = module_id

	await get_tree().process_frame
	_show_chest_animation()


func _load_module(module_id: String) -> Resource:
	if not MODULE_PATHS.has(module_id):
		return null
	var path: String = MODULE_PATHS[module_id]
	if not ResourceLoader.exists(path):
		return null
	return load(path)


# ---------- Анимация сундука ----------

func _show_chest_animation() -> void:
	var vs := get_viewport().get_visible_rect().size

	dim.visible = true
	dim.modulate = Color(1, 1, 1, 0)
	var tw_dim := create_tween()
	tw_dim.tween_property(dim, "modulate", Color(1, 1, 1, 1), 0.3)

	var chest_node: Node2D = CHEST_SCENE.instantiate()
	chest_node.position = vs / 2
	chest_node.position.y -= 60
	add_child(chest_node)

	var chest_sprite: Sprite2D = chest_node.get_node_or_null("Sprite2D")
	var light_anim: AnimatedSprite2D = chest_node.get_node_or_null("Light")
	var audio_player: AudioStreamPlayer = chest_node.get_node_or_null("AudioStreamPlayer")

	if chest_sprite:
		chest_sprite.visible = true
	if light_anim:
		light_anim.visible = false
		light_anim.modulate = RARITY_COLORS.get(_module_rarity, Color.WHITE)

	await get_tree().create_timer(0.5).timeout

	if audio_player:
		audio_player.play()

	# Подготавливаем ModuleButton заранее — скрытым
	var btn: ModuleButton = MODULE_BUTTON_SCENE.instantiate()
	btn.text = ""
	btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.disabled = false
	module_btn_holder.add_child(btn)
	btn.setup(_module_id)
	await get_tree().process_frame
	btn.position = (module_btn_holder.size - btn.size) / 2
	btn.modulate = Color(1, 1, 1, 0)

	if light_anim:
		light_anim.visible = true
		# Градиент: начинаем с цвета редкости
		var rarity_glow: Color = RARITY_COLORS.get(_module_rarity, Color.WHITE)
		light_anim.modulate = rarity_glow
		light_anim.play("default")
		# Последовательное перетекание цвета: цвет редкости → белый → золотой → обратно
		var tw_glow := create_tween()
		tw_glow.tween_property(light_anim, "modulate", Color.WHITE, 0.6).set_trans(Tween.TRANS_SINE)
		tw_glow.tween_property(light_anim, "modulate", Color(1.0, 0.85, 0.3, 1), 0.6).set_trans(Tween.TRANS_SINE)
		# На середине (после золотого) начинаем плавно проявлять иконку
		tw_glow.tween_property(light_anim, "modulate", rarity_glow, 0.6).set_trans(Tween.TRANS_SINE)
		tw_glow.tween_property(light_anim, "modulate", Color.WHITE, 0.6).set_trans(Tween.TRANS_SINE)
		tw_glow.tween_property(light_anim, "modulate", rarity_glow, 0.6).set_trans(Tween.TRANS_SINE)
		# Задержка 0.2 сек на финальном цвете
		tw_glow.tween_property(light_anim, "modulate", rarity_glow, 0.5)
		# Параллельно — появление иконки с задержкой ~1.2 сек (после первых двух переходов)
		var tw_btn := create_tween()
		tw_btn.tween_property(btn, "modulate", Color(1, 1, 1, 1), 0.8).set_delay(1.2).set_trans(Tween.TRANS_SINE)
		await tw_glow.finished
		light_anim.visible = false
		if chest_sprite:
			chest_sprite.visible = false

	_show_module_result(btn)


# ---------- Отображение результата ----------

func _show_module_result(btn: ModuleButton = null) -> void:
	# Удаляем только ноды сундука (Node2D), а не Controls из сцены
	for child in get_children():
		if child is Node2D and child != dim:
			child.queue_free()

	# Если кнопка не передана (старый вызов) — создаём
	if btn == null:
		btn = MODULE_BUTTON_SCENE.instantiate()
		btn.text = ""
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.disabled = false
		module_btn_holder.add_child(btn)
		btn.setup(_module_id)
		await get_tree().process_frame
		btn.position = (module_btn_holder.size - btn.size) / 2

	# Включаем панель на случай если она была выключена
	panel.visible = true

	# === Показываем панель ===
	panel.modulate = Color(1, 1, 1, 0)
	panel.visible = true
	var tw_p := create_tween()
	tw_p.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.3)

	# === Название ===
	name_label.text = _module_name
	name_label.modulate = Color(1, 1, 1, 0)
	name_label.visible = true
	var tw_n := create_tween()
	tw_n.tween_property(name_label, "modulate", Color(1, 1, 1, 1), 0.3)

	# === Раритет ===
	var rarity_color: Color = RARITY_COLORS.get(_module_rarity, Color.WHITE)
	var rarity_text: String = RARITY_NAMES.get(_module_rarity, _module_rarity)
	rarity_label.text = rarity_text
	rarity_label.add_theme_color_override("font_color", rarity_color)
	rarity_label.modulate = Color(1, 1, 1, 0)
	rarity_label.visible = true
	var tw_r := create_tween()
	tw_r.tween_property(rarity_label, "modulate", Color(1, 1, 1, 1), 0.3)

	# === Прогресс счётчик: получено / всего ===
	if _total_count > 0:
		progress_label.visible = true
		progress_label.text = "Получено: %d / %d" % [_obtained_count, _total_count]
		progress_label.modulate = Color(1, 1, 1, 0)
		var tw_prog := create_tween()
		tw_prog.tween_property(progress_label, "modulate", Color(1, 1, 1, 1), 0.3)
	else:
		progress_label.visible = false

	# === Текст дубликата ===
	if _is_duplicate:
		duplicate_label.visible = true
		duplicate_label.modulate = Color(1, 1, 1, 0)
		var tw_c := create_tween()
		tw_c.tween_property(duplicate_label, "modulate", Color(1, 1, 1, 1), 0.3)
		again_btn.text = "Открыть ещё\n(500)"
	else:
		duplicate_label.visible = false
		again_btn.text = "Открыть ещё\n(500)"

	# Кнопки уже в сцене, просто показываем
	accept_btn.modulate = Color(1, 1, 1, 0)
	again_btn.modulate = Color(1, 1, 1, 0)
	var tw_a := create_tween()
	tw_a.tween_property(accept_btn, "modulate", Color(1, 1, 1, 1), 0.3)
	var tw_g := create_tween()
	tw_g.tween_property(again_btn, "modulate", Color(1, 1, 1, 1), 0.3)


func _on_accept_pressed() -> void:
	popup_closed.emit()
	queue_free()


func _on_again_pressed() -> void:
	opened_again_requested.emit()
	queue_free()
