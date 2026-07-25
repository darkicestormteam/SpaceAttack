extends Node

## Сигнал испускается при смене языка
signal language_changed(locale: String)

const DEFAULT_LOCALE: String = "ru"
const CONFIG_PATH: String = "user://localization.cfg"
const TRANSLATIONS_DIR: String = "res://translations/"
const CSV_BASENAME: String = "localization"

var current_locale: String = DEFAULT_LOCALE
var _sdk_lang_applied: bool = false
## Список доступных языков (загружается один раз при инициализации)
var _available_locales: Array[String] = []

func _ready() -> void:
	_load_translations()
	# Принудительно регистрируем ключевые переводы, если их нет в .translation файлах
	_register_fallback_translations()
	_load_locale()
	# Устанавливаем локаль — TranslationServer уже знает все переводы
	TranslationServer.set_locale(current_locale)
	print("[LocalizationManager] Init with locale: ", current_locale)


## Регистрирует fallback-переводы для ключей, которые могут не попасть в .translation
func _register_fallback_translations() -> void:
	var fallbacks: Dictionary = {
		"name_game": {"ru": "Космическая Атака", "en": "Space Attack"}
	}
	
	for key in fallbacks:
		# Проверяем, есть ли уже перевод в TranslationServer
		var existing = TranslationServer.translate(key)
		if existing == key or existing.is_empty():
			# Нет перевода — добавляем через отдельные Translation для каждого языка
			for locale in fallbacks[key]:
				var tr := Translation.new()
				tr.locale = locale
				tr.add_message(key, fallbacks[key][locale])
				TranslationServer.add_translation(tr)
				print("[LocalizationManager] Added fallback translation: ", key, " (", locale, ")")


## Загружает готовые .translation файлы (созданные Godot из CSV)
## через ResourceLoader. Это работает в Web/HTML, так как .translation —
## это оптимизированный ресурс Godot, который гарантированно попадает в PCK.
func _load_translations() -> void:
	var locale_names: Array[String] = []
	
	# Пробуем загрузить известные .translation файлы
	# Имена файлов: localization.en.translation, localization.ru.translation
	var known_locales: Array[String] = ["en", "ru"]
	for loc in known_locales:
		var path: String = TRANSLATIONS_DIR + CSV_BASENAME + "." + loc + ".translation"
		if ResourceLoader.exists(path):
			var tr: Resource = load(path)
			if tr is Translation:
				TranslationServer.add_translation(tr)
				locale_names.append(tr.locale)
				print("[LocalizationManager] Loaded translation: ", path, " (locale: ", tr.locale, ")")
	
	# Если не нашли ни одного .translation — пробуем старый кастомный парсинг
	# для обратной совместимости (редактор/десктоп)
	if locale_names.is_empty():
		print("[LocalizationManager] No .translation files found, trying CSV...")
		_load_translations_from_csv_fallback()
		return
	
	_available_locales = locale_names
	print("[LocalizationManager] Available locales: ", _available_locales)


## Fallback: загружаем из CSV через FileAccess (работает в редакторе/десктопе)
func _load_translations_from_csv_fallback() -> void:
	var csv_path: String = TRANSLATIONS_DIR + CSV_BASENAME + ".csv"
	if not FileAccess.file_exists(csv_path):
		push_error("[LocalizationManager] Fallback CSV not found: ", csv_path)
		return
	
	var file := FileAccess.open(csv_path, FileAccess.READ)
	var content: String = file.get_as_text()
	file.close()
	
	content = content.replace("\r\n", "\n").replace("\r", "\n")
	
	var records: Array[String] = _split_csv_records(content)
	if records.size() < 2:
		return
	
	# Заголовок: key,ru,en,...
	var headers := _parse_csv_line(records[0])
	if headers.size() < 2 or headers[0] != "key":
		push_error("[LocalizationManager] Invalid CSV header in: ", csv_path)
		return
	
	# Колонки языков (всё после 'key')
	var locales: Array[String] = []
	for i in range(1, headers.size()):
		var loc := headers[i].strip_edges()
		if not loc.is_empty():
			locales.append(loc)
	
	if locales.is_empty():
		return
	
	var translations: Dictionary = {}
	for locale in locales:
		var tr := Translation.new()
		tr.locale = locale
		translations[locale] = tr
	
	for i in range(1, records.size()):
		var record := records[i].strip_edges()
		if record.is_empty():
			continue
		var parts := _parse_csv_line(record)
		if parts.size() < 2:
			continue
		var key := parts[0].strip_edges()
		if key.is_empty():
			continue
		for j in locales.size():
			var col_idx := j + 1
			if col_idx < parts.size():
				var msg := parts[col_idx].strip_edges()
				if not msg.is_empty():
					translations[locales[j]].add_message(key, msg)
	
	for locale in translations:
		TranslationServer.add_translation(translations[locale])
	
	_available_locales = locales
	print("[LocalizationManager] Fallback CSV loaded: ", csv_path, " (locales=", locales, ")")


func _split_csv_records(content: String) -> Array[String]:
	var records: Array[String] = []
	var current: String = ""
	var in_quotes: bool = false
	for i in range(content.length()):
		var c := content[i]
		if c == '"':
			in_quotes = not in_quotes
			current += c
		elif c == '\n' and not in_quotes:
			records.append(current)
			current = ""
		else:
			current += c
	if not current.is_empty():
		records.append(current)
	return records


func _parse_csv_line(line: String) -> PackedStringArray:
	var result: PackedStringArray = []
	var current: String = ""
	var in_quotes: bool = false
	for i in range(line.length()):
		var c := line[i]
		if c == '"':
			in_quotes = not in_quotes
		elif c == ',' and not in_quotes:
			result.append(current)
			current = ""
		else:
			current += c
	result.append(current)
	return result


## Получает язык из Яндекс SDK (ysdk.environment.i18n.lang)
## и применяет его, если он поддерживается.
## Соответствует требованию 2.14 модерации Яндекс.Игр.
func apply_language_from_yandex_sdk() -> void:
	if _sdk_lang_applied:
		return
	_sdk_lang_applied = true
	
	var sdk_lang: String = ""
	var ads = get_node_or_null("/root/AdsManager")
	if ads != null and ads.has_method("get_lang"):
		sdk_lang = str(ads.get_lang())
	
	if sdk_lang.is_empty():
		sdk_lang = _get_lang_from_javascript()
	
	if sdk_lang.is_empty():
		print("[LocalizationManager] Yandex SDK lang is empty, keeping current")
		return
	
	var supported := get_available_locales()
	if sdk_lang in supported:
		if sdk_lang != current_locale:
			print("[LocalizationManager] Applying language from Yandex SDK: ", sdk_lang)
			set_locale(sdk_lang)
	else:
		var fallback := "en" if "en" in supported else DEFAULT_LOCALE
		print("[LocalizationManager] SDK lang '%s' not supported, fallback to '%s'" % [sdk_lang, fallback])
		if fallback != current_locale:
			set_locale(fallback)


func _get_lang_from_javascript() -> String:
	if not OS.has_feature("web"):
		return ""
	var js_code = """
		(function() {
			try {
				if (typeof ysdk !== 'undefined' && ysdk.environment && ysdk.environment.i18n && ysdk.environment.i18n.lang) {
					return ysdk.environment.i18n.lang;
				}
				return '';
			} catch(e) {
				return '';
			}
		})()
	"""
	var result = JavaScriptBridge.eval(js_code)
	if result != null and result is String and not result.is_empty():
		print("[LocalizationManager] Got lang from JavaScriptBridge: ", result)
		return result
	return ""


func set_locale(locale: String) -> void:
	if locale == current_locale:
		return
	current_locale = locale
	TranslationServer.set_locale(locale)
	_save_locale()
	language_changed.emit(locale)
	print("[LocalizationManager] Switched to: ", locale)


func get_locale() -> String:
	return current_locale


func get_available_locales() -> Array[String]:
	if _available_locales.is_empty():
		return ["ru", "en"]
	return _available_locales


func _load_locale() -> void:
	"""Загружает сохранённую настройку языка из user-файла."""
	var config := ConfigFile.new()
	var err := config.load(CONFIG_PATH)
	if err == OK:
		var saved: Variant = config.get_value("localization", "locale", "")
		if saved is String and not saved.is_empty():
			current_locale = saved


func _save_locale() -> void:
	"""Сохраняет настройку языка в user-файл."""
	var config := ConfigFile.new()
	config.set_value("localization", "locale", current_locale)
	config.save(CONFIG_PATH)
