extends RefCounted
class_name ModuleIconHelper

## Устаревший helper: иконка модуля по id.
## Источник правды теперь — ModuleVisuals.tres (см. ui/popups/ModuleButton.gd).
## Этот класс оставлен как fallback / для других мест, которым нужна только иконка.

const ICON_PATH_BY_ID: String = "res://assets/sprites/ui/moduls/{id}.png"


static func has_icon(module_id: String) -> bool:
	return ResourceLoader.exists(_path_for(module_id))


static func load_icon(module_id: String) -> Texture2D:
	var path: String = _path_for(module_id)
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


static func _path_for(module_id: String) -> String:
	return ICON_PATH_BY_ID.replace("{id}", module_id)
