extends Node

## Громкость музыки (0.0 - 1.0). По умолчанию 0.5 (середина).
var music_volume: float = 0.5:
	set(value):
		music_volume = clampf(value, 0.0, 1.0)
		_update_audio()
		
## Громкость звуковых эффектов (0.0 - 1.0). По умолчанию 0.5 (середина).
var sfx_volume: float = 0.5:
	set(value):
		sfx_volume = clampf(value, 0.0, 1.0)
		_update_audio()


func _ready() -> void:
	load_settings()


## Преобразует линейную громкость (0.0–1.0) в dB для AudioServer.
## - 0.0 → -80 dB (тишина), 0.5 → -6 dB, 1.0 → 0 dB
static func _linear_to_db(value: float) -> float:
	if value <= 0.0:
		return -80.0
	return linear_to_db(value)


func _update_audio() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), _linear_to_db(music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), _linear_to_db(sfx_volume))
	save_settings()


func set_music_volume(value: float) -> void:
	music_volume = value


func set_sfx_volume(value: float) -> void:
	sfx_volume = value


func save_settings() -> void:
	var file = FileAccess.open("user://audio_settings.json", FileAccess.WRITE)
	if file:
		var data = {
			"music_volume": music_volume,
			"sfx_volume": sfx_volume
		}
		file.store_string(JSON.new().stringify(data))
		file.close()


func load_settings() -> void:
	if not FileAccess.file_exists("user://audio_settings.json"):
		# Первый запуск — ставим 0.5 по умолчанию
		music_volume = 0.5
		sfx_volume = 0.5
		_update_audio()
		return
	var file = FileAccess.open("user://audio_settings.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var parse_result = json.parse(file.get_as_text())
		file.close()
		if parse_result == OK:
			var data = json.data as Dictionary
			music_volume = data.get("music_volume", 0.5)
			sfx_volume = data.get("sfx_volume", 0.5)
			_update_audio()
		else:
			music_volume = 0.5
			sfx_volume = 0.5
			_update_audio()
