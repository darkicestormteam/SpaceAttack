extends Node

## Сигнал испускается при смене языка
signal language_changed(locale: String)

const DEFAULT_LOCALE: String = "ru"
const CONFIG_PATH: String = "user://localization.cfg"
const TRANSLATIONS_CSV_PATH: String = "res://translations/localization.csv"

var current_locale: String = DEFAULT_LOCALE
var _sdk_lang_applied: bool = false

func _ready() -> void:
	_load_translations_from_csv()
	_load_locale()
	# Устанавливаем локаль, но не окончательно — позже SDK может переопределить
	TranslationServer.set_locale(current_locale)
	print("[LocalizationManager] Init with locale: ", current_locale)
	
	# Подписываемся на готовность SDK, чтобы применить язык из Яндекс.Игр
	# Это гарантирует прохождение проверки I18N модерации (требование 2.14)
	var ads = get_node_or_null("/root/AdsManager")
	if ads:
		if ads.is_sdk_ready:
			apply_language_from_yandex_sdk()
		elif not ads.is_connected("init_completed", _on_sdk_init):
			ads.init_completed.connect(_on_sdk_init)


func _on_sdk_init(_success: bool) -> void:
	apply_language_from_yandex_sdk()


## Получает язык из Яндекс SDK (ysdk.environment.i18n.lang)
## и применяет его, если он поддерживается.
## Соответствует требованию 2.14 модерации Яндекс.Игр:
## игра должна автоматически определять язык интерфейса из SDK.
func apply_language_from_yandex_sdk() -> void:
	if _sdk_lang_applied:
		return
	_sdk_lang_applied = true
	
	# Пробуем получить язык из AdsManager (через YandexSDK.get_environment())
	var sdk_lang: String = ""
	var ads = get_node_or_null("/root/AdsManager")
	if ads != null and ads.has_method("get_lang"):
		sdk_lang = str(ads.get_lang())
	
	# Если AdsManager не дал язык — пробуем напрямую через JavaScriptBridge
	# (важно для прохождения I18N проверки модерации Яндекс.Игр)
	if sdk_lang.is_empty():
		sdk_lang = _get_lang_from_javascript()
	
	if sdk_lang.is_empty():
		print("[LocalizationManager] Yandex SDK lang is empty, keeping current")
		return
	
	# Проверяем, поддерживается ли этот язык (есть ли в CSV)
	var supported := get_available_locales()
	if sdk_lang in supported:
		if sdk_lang != current_locale:
			print("[LocalizationManager] Applying language from Yandex SDK: ", sdk_lang)
			set_locale(sdk_lang)
	else:
		# Если язык не поддерживается — переключаем на fallback (en или ru)
		var fallback := "en" if "en" in supported else DEFAULT_LOCALE
		print("[LocalizationManager] SDK lang '%s' not supported, fallback to '%s'" % [sdk_lang, fallback])
		if fallback != current_locale:
			set_locale(fallback)


## Прямое получение языка из ysdk.environment.i18n.lang через JavaScriptBridge.
## Используется как fallback, если AdsManager ещё не инициализирован.
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


func _load_translations_from_csv() -> void:
	"""Загружает переводы из CSV-файла.
	В Godot 4 Web/HTML сборке DirAccess для res:// не работает,
	поэтому используем прямой путь к файлу."""
	_parse_csv_file(TRANSLATIONS_CSV_PATH)


func _parse_csv_file(path: String) -> void:
	"""Парсит CSV-файл и регистрирует переводы в TranslationServer."""
	if not FileAccess.file_exists(path):
		push_error("[LocalizationManager] CSV not found: ", path)
		return
	
	var file := FileAccess.open(path, FileAccess.READ)
	var content: String = file.get_as_text()
	file.close()
	
	content = content.replace("\r\n", "\n").replace("\r", "\n")
	
	# Разбиваем на строки с учётом многострочных кавычек
	var records: Array[String] = _split_csv_records(content)
	if records.size() < 2:
		return
	
	# Заголовок: key,ru,en,...
	var headers := _parse_csv_line(records[0])
	if headers.size() < 2 or headers[0] != "key":
		push_error("[LocalizationManager] Invalid CSV header in: ", path)
		return
	
	# Колонки языков (всё после 'key')
	var locales: Array[String] = []
	for i in range(1, headers.size()):
		var loc := headers[i].strip_edges()
		if not loc.is_empty():
			locales.append(loc)
	
	if locales.is_empty():
		return
	
	# Создаём Translation для каждого языка
	var translations: Dictionary = {}  # locale -> Translation
	for locale in locales:
		var tr := Translation.new()
		tr.locale = locale
		translations[locale] = tr
	
	# Парсим строки с данными
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
	
	# Регистрируем переводы
	var count := 0
	for locale in translations:
		TranslationServer.add_translation(translations[locale])
		count += translations[locale].get_message_list().size()
	
	print("[LocalizationManager] Loaded CSV: ", path, " (locales=", locales, ")")


func _split_csv_records(content: String) -> Array[String]:
	"""Разбивает CSV-контент на записи, учитывая многострочные значения в кавычках."""
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
	"""Парсит одну строку CSV с поддержкой кавычек."""
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


func set_locale(locale: String) -> void:
	"""Переключает язык интерфейса."""
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
	"""Возвращает список доступных языков."""
	var locales: Array[String] = []
	if not FileAccess.file_exists(TRANSLATIONS_CSV_PATH):
		return ["ru", "en"]
	
	var file := FileAccess.open(TRANSLATIONS_CSV_PATH, FileAccess.READ)
	if file:
		var header := file.get_line().strip_edges()
		var parts := _parse_csv_line(header)
		for i in range(1, parts.size()):
			var loc := parts[i].strip_edges()
			if not loc.is_empty() and not loc in locales:
				locales.append(loc)
		file.close()
	
	if locales.is_empty():
		locales = ["ru", "en"]
	return locales


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
