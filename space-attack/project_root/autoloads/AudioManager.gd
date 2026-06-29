extends Node

var _music_volume: float = 0.5
var _sfx_volume: float = 0.5

## Публичный геттер для музыки.
var music_volume: float:
	get:
		return _music_volume
	set(value):
		_music_volume = clampf(value, 0.0, 1.0)
		if _music_volume > 0.0:
			_last_nonzero_music = _music_volume
		_update_audio()
		
## Публичный геттер для SFX.
var sfx_volume: float:
	get:
		return _sfx_volume
	set(value):
		_sfx_volume = clampf(value, 0.0, 1.0)
		if _sfx_volume > 0.0:
			_last_nonzero_sfx = _sfx_volume
		_update_audio()

## Последняя ненулевая громкость музыки (чтобы включить обратно)
var _last_nonzero_music: float = 0.5
## Последняя ненулевая громкость звуков
var _last_nonzero_sfx: float = 0.5


func _ready() -> void:
	load_settings()


static func _linear_to_db(value: float) -> float:
	if value <= 0.0:
		return -80.0
	return linear_to_db(value)


func _update_audio() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), _linear_to_db(_music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), _linear_to_db(_sfx_volume))
	save_settings()


func set_music_volume(value: float) -> void:
	music_volume = value  # через setter


func set_sfx_volume(value: float) -> void:
	sfx_volume = value  # через setter


## Прямое изменение громкости БЕЗ обновления _last_nonzero (для слайдеров).
## Работает напрямую с _music_volume, минуя setter.
func set_music_volume_direct(value: float) -> void:
	_music_volume = clampf(value, 0.0, 1.0)
	_update_audio()


func set_sfx_volume_direct(value: float) -> void:
	_sfx_volume = clampf(value, 0.0, 1.0)
	_update_audio()


## Переключить музыку вкл/выкл. Сохраняет громкость в _last_nonzero ДО выключения.
func toggle_music() -> void:
	if _music_volume > 0.0:
		_last_nonzero_music = _music_volume  # сохраняем явно
		_music_volume = 0.0
		_update_audio()
	else:
		music_volume = _last_nonzero_music  # через setter


func toggle_sfx() -> void:
	if _sfx_volume > 0.0:
		_last_nonzero_sfx = _sfx_volume
		_sfx_volume = 0.0
		_update_audio()
	else:
		sfx_volume = _last_nonzero_sfx


func reset_settings() -> void:
	_music_volume = 0.5
	_sfx_volume = 0.5
	_last_nonzero_music = 0.5
	_last_nonzero_sfx = 0.5
	_update_audio()


func save_settings() -> void:
	var file = FileAccess.open("user://audio_settings.json", FileAccess.WRITE)
	if file:
		var data = {
			"music_volume": _music_volume,
			"sfx_volume": _sfx_volume,
			"_last_nonzero_music": _last_nonzero_music,
			"_last_nonzero_sfx": _last_nonzero_sfx
		}
		file.store_string(JSON.new().stringify(data))
		file.close()


func load_settings() -> void:
	if not FileAccess.file_exists("user://audio_settings.json"):
		_music_volume = 0.5
		_sfx_volume = 0.5
		_last_nonzero_music = 0.5
		_last_nonzero_sfx = 0.5
		_update_audio()
		return
	var file = FileAccess.open("user://audio_settings.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var parse_result = json.parse(file.get_as_text())
		file.close()
		if parse_result == OK:
			var data = json.data as Dictionary
			_music_volume = data.get("music_volume", 0.5)
			_sfx_volume = data.get("sfx_volume", 0.5)
			_last_nonzero_music = data.get("_last_nonzero_music", 0.5)
			_last_nonzero_sfx = data.get("_last_nonzero_sfx", 0.5)
			_update_audio()
		else:
			_music_volume = 0.5
			_sfx_volume = 0.5
			_last_nonzero_music = 0.5
			_last_nonzero_sfx = 0.5
			_update_audio()