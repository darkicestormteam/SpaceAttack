extends CanvasLayer

# Popup, который показывает результат открытия сундука.

signal popup_closed

const MODULE_PATHS: Dictionary = {
	"shotgun": "res://data/modules/shotgun.tres",
	"shield": "res://data/modules/shield.tres",
	"shockwave": "res://data/modules/shockwave.tres"
}

@onready var title_label: Label = %TitleLabel
@onready var result_label: Label = %ResultLabel
@onready var close_button: Button = %CloseButton


func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)


# mode: "new" — новый модуль; "duplicate" — модуль уже был, выдана компенсация
func setup(module_id: String, is_new: bool, compensation: int) -> void:
	var module_resource: Resource = _load_module(module_id)
	var display_name: String = module_id
	if module_resource != null and "name" in module_resource:
		display_name = str(module_resource.name)

	if is_new:
		title_label.text = "🎁 Новый модуль!"
		result_label.text = "Вы получили: %s\nОн автоматически экипирован." % display_name
	else:
		title_label.text = "💰 Дубликат"
		result_label.text = "У вас уже есть \"%s\".\nКомпенсация: +%d ⭐" % [display_name, compensation]


func _load_module(module_id: String) -> Resource:
	if not MODULE_PATHS.has(module_id):
		return null
	var path: String = MODULE_PATHS[module_id]
	if not ResourceLoader.exists(path):
		return null
	return load(path)


func _on_close_pressed() -> void:
	popup_closed.emit()
	queue_free()
