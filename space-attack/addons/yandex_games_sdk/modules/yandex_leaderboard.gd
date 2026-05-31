## A Module for Managing Leaderboards in Yandex Games.
## 
## [b]@version[/b] 1.0.3 (updated for new Yandex API)
## [b]@author[/b] Mist1351 (modified)
## [br]
## A Module for managing leaderboard interactions in Yandex Games, including initializing leaderboards, submitting player scores, and retrieving leaderboard data.[br]
## [br]
## [b]@see[/b] [url]https://yandex.ru/dev/games/doc/en/sdk/sdk-leaderboard[/url]
class_name YandexLeaderboard extends YandexModule


## Emitted when the initialization process is successfully completed.
signal init_succeeded()
## Emitted when the initialization process fails.[br]
## [b]@param[/b] {[String]} [param error_] — A message describing the reason for the failure.
signal init_failed(error_:String)
## Emitted when the leaderboard description is successfully retrieved.[br]
## [b]@param[/b] {[Dictionary]} [param description_] — A dictionary containing the details of the leaderboard.
signal get_description_succeeded(description_:Dictionary)
##  Emitted when retrieving the leaderboard description fails.[br]
## [b]@param[/b] {[String]} [param error_] — A message describing the reason for the failure.
signal get_description_failed(error_:String)
## Emitted when the timeout for calling the [method get_description] method ends, indicating that the ad can be called again.
signal get_description_timeout()
## Emitted when the user's score is successfully submitted to the leaderboard.
signal set_score_succeeded()
## Emitted when submitting the user's score to the leaderboard fails.[br]
## [b]@param[/b] {[String]} [param error_] — A message describing the reason for the failure.
signal set_score_failed(error_:String)
## Emitted when the timeout for calling the [method set_score] method ends, indicating that the ad can be called again.
signal set_score_timeout()
## Emitted when the player's leaderboard entry is successfully retrieved.[br]
## [b]@param[/b] {[Dictionary]} [param entry_] — A dictionary containing the details of the player's leaderboard entry.
signal get_player_entry_succeeded(entry_:Dictionary)
## Emitted when retrieving the player's leaderboard entry fails.[br]
## [b]@param[/b] {[String]} [param error_] — A message describing the reason for the failure.[br]
## [b]@param[/b] {[Variant]} [param code_] — An error code providing additional details about the failure. Can have one of the following values:[br]
## [b]    •[/b] [code]null[/code]: No specific error code is available.[br]
## [b]    •[/b] [constant YandexLeaderboard.CODE_LEADERBOARD_PLAYER_NOT_PRESENT]: The leaderboard doesn't have an entry for the player.
signal get_player_entry_failed(error_:String, code_:Variant)
## Emitted when the timeout for calling the [method get_player_entry] method ends, indicating that the ad can be called again.
signal get_player_entry_timeout()
##  Emitted when the leaderboard entries are successfully retrieved.[br]
## [b]@param[/b] {[Dictionary]} [param data_] — A dictionary containing the details of the retrieved leaderboard entries.
signal get_entries_succeeded(data_:Dictionary)
## Emitted when retrieving the leaderboard entries fails.[br]
## [b]@param[/b] {[String]} [param error_] — A message describing the reason for the failure.
signal get_entries_failed(error_:String)
## Emitted when the timeout for calling the [method get_entries] method ends, indicating that the ad can be called again.
signal get_entries_timeout()


## Leaderboard type representing numeric values.
const TYPE_NUMERIC = "numeric"
## Leaderboard type representing time in seconds.
const TYPE_TIME = "time"

## The leaderboard doesn't have an entry for the player.
const CODE_LEADERBOARD_PLAYER_NOT_PRESENT = "LEADERBOARD_PLAYER_NOT_PRESENT"

## A call rate limiter for managing the frequency of [method get_description] calls.
var crl_get_description:YandexUtils.CallRateLimiter = YandexUtils.CallRateLimiter.new(get_description_timeout, 5 * 60 * 1000, 20)
## A call rate limiter for managing the frequency of [method set_score] calls.
var crl_set_score:YandexUtils.CallRateLimiter = YandexUtils.CallRateLimiter.new(set_score_timeout, 60 * 1000, 60)
## A call rate limiter for managing the frequency of [method get_player_entry] calls.
var crl_get_player_entry:YandexUtils.CallRateLimiter = YandexUtils.CallRateLimiter.new(get_player_entry_timeout, 5 * 60 * 1000, 60)
## A call rate limiter for managing the frequency of [method get_entries] calls.
var crl_get_entries:YandexUtils.CallRateLimiter = YandexUtils.CallRateLimiter.new(get_entries_timeout, 5 * 60 * 1000, 20)


var _leaderboard_available: bool = false   # флаг, что модуль готов (без отдельного объекта)
var _get_player_entry_code = null


func _init(yandex_sdk_:YandexGamesSDK) -> void:
	super(yandex_sdk_)
	
	if null != _yandex_sdk:
		_yandex_sdk._push_crl(crl_get_description)
		_yandex_sdk._push_crl(crl_set_score)
		_yandex_sdk._push_crl(crl_get_player_entry)
		_yandex_sdk._push_crl(crl_get_entries)


func _parse_description_js_object(description_:JavaScriptObject) -> Dictionary:
	return {
		"app_id": YandexUtils.get_property(description_, ["appID"]),
		"dеfault": YandexUtils.get_property(description_, ["default"]),
		"description": {
			"invert_sort_order": YandexUtils.get_property(description_, ["description", "invert_sort_order"]),
			"score_format": {
				"options": {
					"decimal_offset": YandexUtils.get_property(description_, ["description", "score_format", "options", "decimal_offset"]),
				},
				"type": YandexUtils.get_property(description_, ["description", "score_format", "type"]),
			},
		},
		"name": YandexUtils.get_property(description_, ["name"]),
		"title": JSON.parse_string(YandexUtils.js_json.stringify(YandexUtils.get_property(description_, ["title"]))),
	}


func _parse_entry_js_object(entry_:JavaScriptObject) -> Dictionary:
	var avatar_src = {
		"small": null,
		"medium": null,
		"large": null,
	}
	if YandexUtils.has_property(entry_, ["player","getAvatarSrc"]):
		avatar_src.small = entry_.player.getAvatarSrc("small")
		avatar_src.medium = entry_.player.getAvatarSrc("medium")
		avatar_src.large = entry_.player.getAvatarSrc("large")
	
	var avatar_src_set = {
		"small": null,
		"medium": null,
		"large": null,
	}
	if YandexUtils.has_property(entry_, ["player","getAvatarSrcSet"]):
		avatar_src_set.small = entry_.player.getAvatarSrcSet("small")
		avatar_src_set.medium = entry_.player.getAvatarSrcSet("medium")
		avatar_src_set.large = entry_.player.getAvatarSrcSet("large")
	
	return {
		"score": YandexUtils.get_property(entry_, ["score"]),
		"extra_data": YandexUtils.get_property(entry_, ["extraData"]),
		"rank": YandexUtils.get_property(entry_, ["rank"]),
		"player": {
			"avatar_src": avatar_src,
			"avatar_src_set": avatar_src_set,
			"lang": YandexUtils.get_property(entry_, ["player", "lang"]),
			"public_name": YandexUtils.get_property(entry_, ["player","publicName"]),
			"scope_permissions": {
				"avatar": YandexUtils.get_property(entry_, ["player","scopePermissions", "avatar"]),
				"public_name": YandexUtils.get_property(entry_, ["player","scopePermissions", "public_name"]),
			},
			"unique_id": YandexUtils.get_property(entry_, ["player","uniqueID"]),
		},
		"formatted_score": YandexUtils.get_property(entry_, ["formattedScore"]),
	}


## [b]@async[/b][br]
## Initialize the [YandexLeaderboard].[br]
## [br]
## [color=gold][b]@warning:[/b][/color] This method must be called once before using other methods of [YandexLeaderboard].[br]
## [br]
## [b]@emits[/b] [signal YandexGamesSDK.sdk_error] — Internal SDK error.[br]
## [b]@emits[/b] [signal init_succeeded] — The request was completed successfully.[br]
## [b]@emits[/b] [signal init_failed] — The request failed with an error.[br]
## [br]
## [b]@returns[/b] [code]null[/code] — [YandexGamesSDK] is not initialized.[br]
## [b]@returns[/b] [bool] — [code]true[/code] if [YandexLeaderboard] is initialized; otherwise, [code]false[/code].[br]
## [b]@see[/b] [url]https://yandex.ru/dev/games/doc/en/sdk/sdk-leaderboard#init[/url]
func init() -> Variant:
	# Новый API не требует отдельной инициализации через getLeaderboards.
	# Просто проверяем, что объект ysdk.leaderboards существует.
	if !_check_availability(["leaderboards"]):
		return null
	_leaderboard_available = true
	init_succeeded.emit()
	return true


## Returns the initialization state of [YandexLeaderboard].[br]
## [br]
## [b]@returns[/b] [bool] — [code]true[/code] if [YandexLeaderboard] is initialized; otherwise, [code]false[/code].
func is_inited() -> bool:
	return _is_inited() and _leaderboard_available


## [b]@async[/b][br]
## Get a description of a leaderboard by its name.[br]
## [br]
## [b]@param[/b] {[String]} [param name_] — Leaderboard name.[br]
## [br]
## [b]@emits[/b] [signal YandexGamesSDK.sdk_error] — Internal SDK error.[br]
## [b]@emits[/b] [signal get_description_succeeded] — The request was completed successfully.[br]
## [b]@emits[/b] [signal get_description_failed] — The request failed with an error.[br]
## [br]
## [b]@returns[/b] [code]null[/code] — on error.[br]
## [b]@returns[/b] [Dictionary] — Leaderboard description.
func get_description(name_:String) -> Variant:
	if !_check_availability(["leaderboards", "getDescription"]):
		return null
	
	var result := await Promise.new(_yandex_sdk._ysdk.leaderboards.getDescription(name_)).wait()
	if !result.status:
		get_description_failed.emit(YandexUtils.js_utils.stringify(result.value[0]))
		return null
	
	crl_get_description.apply()
	
	var description := _parse_description_js_object(result.value[0])
	get_description_succeeded.emit(description)
	return description


## [b]@async[/b][br]
## Set a new score for a player.[br]
## [br]
## [b]@param[/b] {[String]} [param name_] — Leaderboard name.[br]
## [b]@param[/b] {[int]} [param score_] — Score.[br]
## [b]@param[/b] {[String]} [lb][param extra_data_][kbd] = ""[/kbd][rb] — User description.[br]
## [br]
## [b]@emits[/b] [signal YandexGamesSDK.sdk_error] — Internal SDK error.[br]
## [b]@emits[/b] [signal set_score_succeeded] — The request was completed successfully.[br]
## [b]@emits[/b] [signal set_score_failed] — The request failed with an error.[br]
## [br]
## [b]@returns[/b] [code]null[/code] or [bool] — success status.
func set_score(name_:String, score_:int, extra_data_:String = "") -> Variant:
	if !_check_availability(["leaderboards", "setScore"]):
		return null
	
	# Проверка доступности метода для авторизованных пользователей
	if !(await _is_available_method("leaderboards.setScore")):
		set_score_failed.emit("User doesn't have permission to call leaderboards.setScore()!")
		return null
	
	crl_set_score.apply()
	
	# Вызов напрямую ysdk.leaderboards.setScore
	var result := await Promise.new(_yandex_sdk._ysdk.leaderboards.setScore(name_, score_, extra_data_)).wait()
	if result.status:
		set_score_succeeded.emit()
	else:
		set_score_failed.emit(YandexUtils.js_utils.stringify(result.value[0]))
	
	return result.status


## [b]@async[/b][br]
## Get a user's ranking.[br]
## [br]
## [b]@param[/b] {[String]} [param name_] — Leaderboard name.[br]
## [br]
## [b]@emits[/b] [signal YandexGamesSDK.sdk_error] — Internal SDK error.[br]
## [b]@emits[/b] [signal get_player_entry_succeeded] — The request was completed successfully.[br]
## [b]@emits[/b] [signal get_player_entry_failed] — The request failed with an error.[br]
## [br]
## [b]@returns[/b] [code]null[/code] — on error.[br]
## [b]@returns[/b] [Dictionary] — User leaderboard entry.
func get_player_entry(name_:String) -> Variant:
	_get_player_entry_code = null
	
	if !_check_availability(["leaderboards", "getPlayerEntry"]):
		return null
	
	if !(await _is_available_method("leaderboards.getPlayerEntry")):
		set_score_failed.emit("User doesn't have permission to call leaderboards.getPlayerEntry()!")
		return null
	
	crl_get_player_entry.apply()
	
	var result := await Promise.new(_yandex_sdk._ysdk.leaderboards.getPlayerEntry(name_)).wait()
	if !result.status:
		_get_player_entry_code = YandexUtils.get_property(result.value[0], ["code"])
		get_player_entry_failed.emit(YandexUtils.js_utils.stringify(result.value[0]), _get_player_entry_code)
		return null
	
	var entry:Dictionary = _parse_entry_js_object(result.value[0])
	get_player_entry_succeeded.emit(entry)
	return entry


## [b]@async[/b][br]
## Leaderboard entries.[br]
## [br]
## [b]@param[/b] {[String]} [param name_] — Leaderboard name.[br]
## [b]@param[/b] {[bool]} [lb][param include_user_][kbd] = false[/kbd][rb] — Include logged-in user.[br]
## [b]@param[/b] {[int]} [lb][param quantity_around_][kbd] = 5[/kbd][rb] — Entries around user.[br]
## [b]@param[/b] {[int]} [lb][param quantity_top_][kbd] = 5[/kbd][rb] — Top entries.[br]
## [br]
## [b]@returns[/b] [code]null[/code] — on error.[br]
## [b]@returns[/b] [Dictionary] — Leaderboard entries data.
func get_entries(name_:String, include_user_:bool = false, quantity_around_:int = 5, quantity_top_:int = 5) -> Variant:
	if !_check_availability(["leaderboards", "getEntries"]):
		return null
	
	var params:JavaScriptObject = JavaScriptBridge.create_object("Object")
	params["includeUser"] = include_user_
	params["quantityAround"] = quantity_around_
	params["quantityTop"] = quantity_top_
	
	var result := await Promise.new(_yandex_sdk._ysdk.leaderboards.getEntries(name_, params)).wait()
	if !result.status:
		get_entries_failed.emit(YandexUtils.js_utils.stringify(result.value[0]))
		return null
	
	crl_get_entries.apply()
	
	var ranges:Array[Dictionary] = []
	if YandexUtils.has_property(result.value[0], ["ranges"]):
		for i in result.value[0].ranges.length:
			var item = result.value[0].ranges[i]
			ranges.push_back({
				"start": YandexUtils.get_property(item, ["start"]),
				"size": YandexUtils.get_property(item, ["size"]),
			})
	
	var entries:Array[Dictionary] = []
	if YandexUtils.has_property(result.value[0], ["entries"]):
		for i in result.value[0].entries.length:
			var item = result.value[0].entries[i]
			entries.push_back(_parse_entry_js_object(item))
	
	var data:Dictionary = {
		"leaderboard": _parse_description_js_object(YandexUtils.get_property(result.value[0], ["leaderboard"])),
		"ranges": ranges,
		"user_rank": YandexUtils.get_property(result.value[0], ["userRank"]),
		"entries": entries,
	}
	get_entries_succeeded.emit(data)
	return data


## Retrieve the possible error code after calling the [method get_player_entry] method.
func get_player_entry_code() -> Variant:
	return _get_player_entry_code
