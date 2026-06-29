extends CanvasLayer

## Всплывающее окно настроек звука.
## Ползунки громкости музыки и звуков.

signal popup_closed

var dim: ColorRect
var panel: VBoxContainer
var music_slider: HSlider
var sfx_slider: HSlider
var music_label: Label
var sfx_label: Label
var close_btn: Button

var _prev_music_volume: float = 0.5
var _prev_sfx_volume: float = 0.5


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_sync_settings_sliders()
	_show_animation()


func _build_ui() -> void:
	dim = ColorRect.new()
	dim.name = "AudioSettingsDim"
	dim.color = Color(0.0, 0.0, 0.0, 0.882)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(dim)

	panel = VBoxContainer.new()
	panel.name = "AudioSettingsPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -250
	panel.offset_top = -250
	panel.offset_right = 250
	panel.offset_bottom = 250
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.add_theme_constant_override("separation", 20)
	panel.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(panel)

	var title := Label.new()
	title.text = "НАСТРОЙКИ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	panel.add_child(spacer)

	var music_row := HBoxContainer.new()
	music_row.alignment = BoxContainer.ALIGNMENT_CENTER
	music_row.add_theme_constant_override("separation", 15)
	music_row.custom_minimum_size = Vector2(400, 60)
	panel.add_child(music_row)

	music_label = Label.new()
	music_label.text = "Музыка: 50%"
	music_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	music_label.add_theme_font_size_override("font_size", 22)
	music_label.add_theme_color_override("font_color", Color.WHITE)
	music_label.custom_minimum_size = Vector2(180, 0)
	music_row.add_child(music_label)

	music_slider = HSlider.new()
	music_slider.custom_minimum_size = Vector2(200, 50)
	music_slider.min_value = 0.0
	music_slider.max_value = 1.0
	music_slider.step = 0.01
	music_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	music_slider.value_changed.connect(_on_music_volume_changed)
	music_row.add_child(music_slider)

	var sfx_row := HBoxContainer.new()
	sfx_row.alignment = BoxContainer.ALIGNMENT_CENTER
	sfx_row.add_theme_constant_override("separation", 15)
	sfx_row.custom_minimum_size = Vector2(400, 60)
	panel.add_child(sfx_row)

	sfx_label = Label.new()
	sfx_label.text = "Звуки: 50%"
	sfx_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	sfx_label.add_theme_font_size_override("font_size", 22)
	sfx_label.add_theme_color_override("font_color", Color.WHITE)
	sfx_label.custom_minimum_size = Vector2(180, 0)
	sfx_row.add_child(sfx_label)

	sfx_slider = HSlider.new()
	sfx_slider.custom_minimum_size = Vector2(200, 50)
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.01
	sfx_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	sfx_row.add_child(sfx_slider)

	var close_spacer := Control.new()
	close_spacer.custom_minimum_size = Vector2(0, 15)
	panel.add_child(close_spacer)

	close_btn = Button.new()
	close_btn.text = "Закрыть"
	close_btn.custom_minimum_size = Vector2(200, 64)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.add_theme_font_size_override("font_size", 24)
	close_btn.pressed.connect(_on_close)
	panel.add_child(close_btn)


func _show_animation() -> void:
	panel.modulate = Color(1, 1, 1, 0)
	panel.scale = Vector2(0.8, 0.8)
	panel.pivot_offset = panel.size / 2
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "modulate", Color.WHITE, 0.2)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _sync_settings_sliders() -> void:
	var am := get_node_or_null("/root/AudioManager") as Node
	if am == null:
		return
	if music_slider:
		music_slider.value = am.music_volume
	if sfx_slider:
		sfx_slider.value = am.sfx_volume
	_prev_music_volume = am.music_volume
	_prev_sfx_volume = am.sfx_volume
	_update_volume_labels()


func _update_volume_labels() -> void:
	if music_label and music_slider:
		music_label.text = "Музыка: %d%%" % int(music_slider.value * 100.0)
	if sfx_label and sfx_slider:
		sfx_label.text = "Звуки: %d%%" % int(sfx_slider.value * 100.0)


func _on_music_volume_changed(value: float) -> void:
	var am := get_node_or_null("/root/AudioManager") as Node
	if am and am.has_method(&"set_music_volume"):
		am.set_music_volume(value)
	_prev_music_volume = value
	_update_volume_labels()


func _on_sfx_volume_changed(value: float) -> void:
	var am := get_node_or_null("/root/AudioManager") as Node
	if am and am.has_method(&"set_sfx_volume"):
		am.set_sfx_volume(value)
	_prev_sfx_volume = value
	_update_volume_labels()


func _on_close() -> void:
	popup_closed.emit()
	queue_free()
