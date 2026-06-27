extends Node

# Автозагрузчик ресурсов визуальных конфигов.
# Форсирует регистрацию class_name Resource-классов в Godot,
# чтобы .tres файлы могли их корректно загрузить.

func _init() -> void:
	# Принудительная загрузка всех Resource-скриптов визуалов
	_load_script("res://data/visuals/ShockwaveConfig.gd")
	_load_script("res://data/visuals/ShieldConfig.gd")
	_load_script("res://data/visuals/ShieldFlashConfig.gd")
	_load_script("res://data/visuals/CocoonConfig.gd")
	_load_script("res://data/visuals/ReactiveBlastConfig.gd")
	_load_script("res://data/visuals/HealFlashConfig.gd")


func _load_script(path: String) -> void:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res:
			print("[VisualConfigs] Loaded: " + path)
