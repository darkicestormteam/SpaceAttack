extends Control

# ============== КОНСТАНТЫ ==============

const RARITY_COLORS: Dictionary = {
	"common": Color(1, 1, 1, 1),
	"rare": Color(0.3, 0.6, 1, 1),
	"epic": Color(0.7, 0.3, 1, 1),
	"legendary": Color(1, 0.7, 0.1, 1)
}

# === Сундук модулей ===
const MODULE_CHEST_COST: int = 500
const MODULE_CHEST_DUPLICATE_COMPENSATION: int = 100

const MODULE_CHEST_POOL: Array = [
	"laser_mk2", "laser_pierce", "laser_plasma",
	"shotgun", "shotgun_whistle", "shotgun_pressure", "shotgun_heavy",
	"rocket", "rocket_mk2", "rocket_homing", "rocket_nuke",
	"light_armor", "shield", "composite_armor", "forsage",
	"tactical_accelerator", "diffusor", "cocoon_shield",
	"drone", "drone_rare", "drone_epic", "drone_legendary",
	"shockwave", "turbo", "nanobots"
]

# === Сундук скинов ===
const SKIN_CHEST_COST: int = 500
const SKIN_CHEST_DUPLICATE_COMPENSATION: int = 50

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

# === Цены ===
const PHANTOM_COST: int = 2000
const GOLIATH_COST: int = 5000
const HEALTH_BASE_COST: int = 1000
const HEALTH_MAX_LEVEL: int = 3
const HEALTH_COST_MULTIPLIER: int = 2

const MODULE_SELECT_SCENE: PackedScene = preload("res://ui/popups/ModuleSelect.tscn")
const CHEST_OPEN_SCENE: PackedScene = preload("res://ui/popups/ChestOpen.tscn")
const BUY_SHIP_POPUP: PackedScene = preload("res://ui/popups/BuyShipPopup.tscn")
const DIFFICULTY_SELECT_SCENE: PackedScene = preload("res://ui/popups/DifficultySelect.tscn")

# ============== НОДЫ ==============

@onready var credits_label: Label = %CreditsLabel
@onready var high_score_label: Label = %HighScoreLabel

# ===== АНГАР =====
@onready var hangar_content: Control = %HangarContent
@onready var play_button: Button = %PlayButton
@onready var shop_button: Button = %ShopButton
@onready var rewards_button: Button = %RewardsButton
@onready var vanguard_button: Button = %VanguardButton
@onready var phantom_button: Button = %PhantomButton
@onready var goliath_button: Button = %GoliathButton
@onready var weapon_slot: Button = %WeaponSlot
@onready var defense_slot: Button = %DefenseSlot
@onready var utility_slot: Button = %UtilitySlot
@onready var chest_button: Button = %ChestButton
@onready var skin_slot_button: Button = %SkinSlotButton
@onready var vanguard_skin_preview: Control = %VanguardSkinPreview
@onready var phantom_skin_preview: Control = %PhantomSkinPreview
@onready var goliath_skin_preview: Control = %GoliathSkinPreview

# ===== МАГАЗИН =====
@onready var shop_content: Control = %ShopContent
@onready var shop_bg: Panel = %ShopBg

# Корабли
@onready var phantom_buy_button: Button = %PhantomBuyButton
@onready var goliath_buy_button: Button = %GoliathBuyButton

# HP улучшение
@onready var health_buy_button: Button = %HealthBuyButton
@onready var health_level_label: Label = %HealthLevelLabel
@onready var health_cost_label: Label = %HealthCostLabel

# Сундуки
@onready var module_chest_button: Button = %ModuleChestButton
@onready var skin_chest_button: Button = %SkinChestButton

# Покупки за реальные деньги (из сцены)
@onready var iap_all_modules_btn: Button = %IapAllModulesButton
@onready var iap_remove_ads_btn: Button = %IapRemoveAdsButton

@onready var music: AudioStreamPlayer = %Music

# Панели подложки (скрываются в магазине)
@onready var panel: Panel = $Panel
@onready var panel2: Panel = $Panel2
@onready var panel3: Panel = $Panel3

const MODULE_BUTTON_SCENE: PackedScene = preload("res://ui/popups/ModuleButton.tscn")

# ============== ПЕРЕМЕННЫЕ ==============

# Последний открытый сундук: "module" или "skin"
var _last_chest_type: String = "module"

# Флаг: true, когда нажали "Открыть ещё" и старая нода ещё не удалилась
var _is_opening_again: bool = false

# Аудио-кнопки
var settings_btn: Button
var music_toggle_btn: TextureButton
var sfx_toggle_btn: TextureButton

var _prev_music_volume: float = 0.5
var _prev_sfx_volume: float = 0.5

# ModuleButton'ы для превью скинов
var _vanguard_skin_btn: ModuleButton = null
var _phantom_skin_btn: ModuleButton = null
var _goliath_skin_btn: ModuleButton = null

# ============== ГОТОВНОСТЬ ==============

func _ready() -> void:
	_setup_audio_buttons()
	_apply_styles_to_all_buttons()
	SaveManager.load_game()
	
	# Фоновая музыка
	if music:
		music.finished.connect(_on_music_finished)
		if not music.playing and music.stream:
			music.play()
	
	# Ангар
	play_button.pressed.connect(_on_play_pressed)
	shop_button.pressed.connect(_show_shop_tab)
	if rewards_button:
		rewards_button.pressed.connect(_on_rewards_pressed)
	vanguard_button.pressed.connect(_on_vanguard_pressed)
	phantom_button.pressed.connect(_on_phantom_pressed)
	goliath_button.pressed.connect(_on_goliath_pressed)
	weapon_slot.pressed.connect(_on_weapon_slot_pressed)
	defense_slot.pressed.connect(_on_defense_slot_pressed)
	utility_slot.pressed.connect(_on_utility_slot_pressed)
	chest_button.pressed.connect(_on_chest_pressed)
	skin_slot_button.pressed.connect(_on_skin_slot_pressed)
	
	# Магазин — корабли
	if phantom_buy_button:
		phantom_buy_button.pressed.connect(_on_phantom_buy_pressed)
	if goliath_buy_button:
		goliath_buy_button.pressed.connect(_on_goliath_buy_pressed)
	
	# Магазин — HP
	if health_buy_button:
		health_buy_button.pressed.connect(_on_health_buy_pressed)
	
		# Магазин — сундуки
	if module_chest_button:
		module_chest_button.pressed.connect(_on_module_chest_pressed)
	if skin_chest_button:
		skin_chest_button.pressed.connect(_on_skin_chest_pressed)
	
	# Магазин — покупки за реальные деньги
	if iap_all_modules_btn:
		iap_all_modules_btn.pressed.connect(_on_iap_all_modules_pressed)
	if iap_remove_ads_btn:
		iap_remove_ads_btn.pressed.connect(_on_iap_remove_ads_pressed)
	
	# Магазин — кнопка "Назад"
	var back_btn: Button = %BackButton if has_node("%BackButton") else null
	if back_btn:
		back_btn.pressed.connect(_show_hangar_tab)
	
	# Показываем ангар по умолчанию
	_show_hangar_tab()
	
	# Проверка необработанных покупок Yandex Payments
	# Если SDK ещё не готов — подписываемся на сигнал инициализации
	var ads = get_node_or_null("/root/AdsManager")
	if ads != null and ads.has_method("check_unconsumed_purchases"):
		if ads.is_sdk_ready:
			ads.check_unconsumed_purchases()
		elif not ads.is_connected("init_completed", _on_ads_ready_for_purchases):
			ads.init_completed.connect(_on_ads_ready_for_purchases)
	
	# Запускаем инициализацию Yandex SDK, если ещё не запущена
	var ads_mgr = get_node_or_null("/root/AdsManager")
	if ads_mgr != null and ads_mgr.has_method("init_async"):
		if not ads_mgr.is_sdk_ready:
			ads_mgr.init_async()
	
	# Устанавливаем состояние MENU — гарантируем красную иконку в ангаре
	var gm_mgr = get_node_or_null("/root/GameManager")
	if gm_mgr and gm_mgr.has_method("set_state"):
		gm_mgr.set_state(gm_mgr.GameState.MENU)
	elif gm_mgr and gm_mgr.has_method("on_battle_end"):
		gm_mgr.on_battle_end()
	
	# Показываем попап удвоения или рекламу при загрузке ангара
	get_tree().create_timer(0.5).timeout.connect(_on_hangar_loaded)


func _on_hangar_loaded() -> void:
	# Проверяем, есть ли отложенные кредиты для удвоения
	if SaveManager.pending_double_credits > 0:
		_show_double_credits_popup()
	else:
		_show_interstitial_on_hangar_load()


func _hide_hangar_ui() -> void:
	if hangar_content: hangar_content.visible = false
	if shop_content: shop_content.visible = false
	if shop_bg: shop_bg.visible = false
	if panel: panel.visible = false
	if panel2: panel2.visible = false
	if panel3: panel3.visible = false


func _show_hangar_ui() -> void:
	_show_hangar_tab()


func _show_double_credits_popup() -> void:
	var amount = SaveManager.pending_double_credits
	SaveManager.pending_double_credits = 0
	
	# Прячем интерфейс ангара на время всех манипуляций с банком
	_hide_hangar_ui()
	
	var popup_scene = preload("res://ui/popups/DoubleCreditsPopup.tscn")
	if popup_scene == null:
		_show_interstitial_on_hangar_load()
		return
	
	var popup = popup_scene.instantiate()
	add_child(popup)
	popup.setup(amount)
	
	if popup.has_signal("choice_made"):
		var choice = await popup.choice_made
		_handle_double_choice(choice, amount)
	else:
		_show_interstitial_on_hangar_load()


func _handle_double_choice(choice: String, amount: int) -> void:
	var ads = get_node_or_null("/root/AdsManager")
	
	if choice == "yes" and amount > 0 and ads != null:
		# Показываем rewarded рекламу для удвоения
		ads.queue_rewarded_double(amount)
		await ads.queue_completed
		# AdsManager уже начислил amount*2
		amount = amount * 2
	else:
		# Начисляем обычные кредиты
		SaveManager.add_credits(amount)
		# Показываем межстраничную рекламу (если доступна)
		if ads != null and ads.has_method("can_show_interstitial") and ads.can_show_interstitial():
			ads.queue_interstitial()
			await ads.queue_completed
	
	# Анимация перетекания с кнопкой "Принять"
	await _show_credits_animation(amount)
	
	# Возвращаем интерфейс ангара
	_show_hangar_ui()
	update_ui()


func _show_credits_animation(amount: int) -> void:
	var anim_scene = preload("res://ui/popups/DoubleCreditsAnimation.tscn")
	if anim_scene:
		var anim_node = anim_scene.instantiate()
		add_child(anim_node)
		anim_node.setup(amount)
		await anim_node.credits_accepted
		anim_node.queue_free()


func _show_interstitial_on_hangar_load() -> void:
	var ads = get_node_or_null("/root/AdsManager")
	if ads != null and ads.has_method("queue_interstitial"):
		ads.queue_interstitial()


func _on_ads_ready_for_purchases(success: bool) -> void:
	if not success:
		return
	var ads = get_node_or_null("/root/AdsManager")
	if ads != null and ads.has_method("check_unconsumed_purchases"):
		ads.check_unconsumed_purchases()


func _process(delta: float) -> void:
	pass


func _on_music_finished() -> void:
	if music:
		music.play()


# ============== ПЕРЕКЛЮЧЕНИЕ МЕЖДУ АНГАРОМ И МАГАЗИНОМ ==============

func _show_hangar_tab() -> void:
	hangar_content.visible = true
	shop_content.visible = false
	shop_bg.visible = false
	if panel: panel.visible = true
	if panel2: panel2.visible = true
	if panel3: panel3.visible = true
	update_ui()


func _show_shop_tab() -> void:
	hangar_content.visible = false
	shop_content.visible = true
	shop_bg.visible = true
	if panel: panel.visible = false
	if panel2: panel2.visible = false
	if panel3: panel3.visible = false
	_refresh_iap_buttons()
	update_ui()


# ============== ОБНОВЛЕНИЕ UI ==============

func update_ui() -> void:
	# Убеждаемся, что gameplay в stop при любом действии в ангаре
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("set_state") and gm.get_current_state() != gm.GameState.UNKNOWN:
		if gm.get_current_state() != gm.GameState.MENU:
			gm.set_state(gm.GameState.MENU)
	
	credits_label.text = "Кредиты: %d" % SaveManager.credits
	high_score_label.text = " Лучший счёт: " + str(SaveManager.high_score)
	_refresh_ship_buttons()
	_refresh_slot_buttons()
	_refresh_shop_ui()


func _refresh_shop_ui() -> void:
	# Корабли
	_update_ship_buy_button(phantom_buy_button, "phantom", PHANTOM_COST)
	_update_ship_buy_button(goliath_buy_button, "goliath", GOLIATH_COST)
	
	# HP улучшение
	if SaveManager.health_upgrade_level >= HEALTH_MAX_LEVEL:
		health_level_label.text = "Уровень: MAX"
		health_cost_label.text = "Максимум"
		health_buy_button.disabled = true
		health_buy_button.text = "MAX"
	else:
		var health_cost: int = HEALTH_BASE_COST * int(pow(HEALTH_COST_MULTIPLIER, SaveManager.health_upgrade_level))
		health_level_label.text = "Уровень: %d" % SaveManager.health_upgrade_level
		health_cost_label.text = "Цена: %d" % health_cost
		health_buy_button.disabled = SaveManager.credits < health_cost
		health_buy_button.text = "Улучшить HP"
	
	# Сундуки
	var can_afford_modules := SaveManager.credits >= MODULE_CHEST_COST
	module_chest_button.disabled = not can_afford_modules
	module_chest_button.modulate = Color(1, 1, 1, 1) if can_afford_modules else Color(0.7, 0.7, 0.7, 0.8)
	
	var can_afford_skins := SaveManager.credits >= SKIN_CHEST_COST
	skin_chest_button.disabled = not can_afford_skins
	skin_chest_button.modulate = Color(1, 1, 1, 1) if can_afford_skins else Color(0.7, 0.7, 0.7, 0.8)


func _update_ship_buy_button(button: Button, ship_id: String, cost: int) -> void:
	if not button:
		return
	if SaveManager.is_ship_unlocked(ship_id):
		button.text = SaveManager.get_ship_name(ship_id) + " — Куплен"
		button.disabled = true
		return
	if SaveManager.credits < cost:
		button.text = SaveManager.get_ship_name(ship_id) + " — " + str(cost) + " (нет средств)"
		button.disabled = true
		return
	button.text = SaveManager.get_ship_name(ship_id) + " — " + str(cost) + ""
	button.disabled = false


# ============== СЛОТЫ (АНГАР) ==============

func _on_skin_slot_pressed() -> void:
	_open_module_select("skin")


func _refresh_slot_buttons() -> void:
	weapon_slot.text = "Оружие\n%s" % _slot_text("weapon")
	defense_slot.text = "Защита\n%s" % _slot_text("defense")
	utility_slot.text = "Утилита\n%s" % _slot_text("utility")
	weapon_slot.add_theme_color_override("font_color", _slot_color("weapon"))
	defense_slot.add_theme_color_override("font_color", _slot_color("defense"))
	utility_slot.add_theme_color_override("font_color", _slot_color("utility"))
	
	var current_skin_idx := SaveManager.get_current_skin(SaveManager.current_ship)
	var skin_name := SaveManager.get_skin_name(SaveManager.current_ship, current_skin_idx)
	skin_slot_button.text = "Скин\n%s" % skin_name
	var skin_module_id := "skin_%s_%d" % [SaveManager.current_ship, current_skin_idx]
	skin_slot_button.add_theme_color_override("font_color", _slot_color_by_id(skin_module_id))
	
	var can_afford := SaveManager.credits >= MODULE_CHEST_COST
	chest_button.disabled = not can_afford
	chest_button.modulate = Color(1, 1, 1, 1) if can_afford else Color(0.7, 0.7, 0.7, 0.8)


func _slot_text(slot: String) -> String:
	var module_id: String = SaveManager.get_equipped_in_slot(slot)
	if module_id.is_empty():
		return "[пусто]"
	return _module_display_name(module_id)


func _module_display_name(module_id: String) -> String:
	if not MODULE_PATHS.has(module_id):
		return module_id
	var path: String = MODULE_PATHS[module_id]
	if not ResourceLoader.exists(path):
		return module_id
	var res: Resource = load(path)
	if res == null:
		return module_id
	if "name" in res:
		return str(res.name)
	return module_id


func _slot_color(slot: String) -> Color:
	var module_id: String = SaveManager.get_equipped_in_slot(slot)
	if module_id.is_empty():
		return Color(0.7, 0.7, 0.7, 0.8)
	return _slot_color_by_id(module_id)


func _slot_color_by_id(module_id: String) -> Color:
	if module_id.is_empty():
		return Color(0.7, 0.7, 0.7, 0.8)
	var path: String = MODULE_PATHS.get(module_id, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		return Color.WHITE
	var res: Resource = load(path)
	if res == null or not "rarity" in res:
		return Color.WHITE
	return RARITY_COLORS.get(str(res.rarity), Color.WHITE)


# ============== КОРАБЛИ (АНГАР) ==============

func _refresh_ship_buttons() -> void:
	var current = SaveManager.current_ship
	_vanguard_button_text(current)
	_phantom_button_text(current)
	_goliath_button_text(current)
	_update_skin_icons()


func _vanguard_button_text(current: String) -> void:
	vanguard_button.text = "Вангвард\nБазовый"
	vanguard_button.disabled = false
	if current == "vanguard":
		vanguard_button.modulate = Color(1, 1, 1, 1)
		_set_button_active(vanguard_button, true)
	else:
		vanguard_button.modulate = Color(0.7, 0.7, 0.7, 0.8)
		_set_button_active(vanguard_button, false)


func _phantom_button_text(current: String) -> void:
	if SaveManager.is_ship_unlocked("phantom"):
		phantom_button.text = "Фантом\nРывок"
		phantom_button.disabled = false
		if current == "phantom":
			phantom_button.modulate = Color(1, 1, 1, 1)
			_set_button_active(phantom_button, true)
		else:
			phantom_button.modulate = Color(0.7, 0.7, 0.7, 0.8)
			_set_button_active(phantom_button, false)
	else:
		phantom_button.text = "Фантом\n2000"
		phantom_button.disabled = false
		phantom_button.modulate = Color(0.7, 0.7, 0.7, 0.8)
		_set_button_active(phantom_button, false)


func _goliath_button_text(current: String) -> void:
	if SaveManager.is_ship_unlocked("goliath"):
		goliath_button.text = "Голиаф\nТаран"
		goliath_button.disabled = false
		if current == "goliath":
			goliath_button.modulate = Color(1, 1, 1, 1)
			_set_button_active(goliath_button, true)
		else:
			goliath_button.modulate = Color(0.7, 0.7, 0.7, 0.8)
			_set_button_active(goliath_button, false)
	else:
		goliath_button.text = "Голиаф\n5000"
		goliath_button.disabled = false
		goliath_button.modulate = Color(0.7, 0.7, 0.7, 0.8)
		_set_button_active(goliath_button, false)


func _on_vanguard_pressed() -> void:
	SaveManager.select_ship("vanguard")
	update_ui()


func _on_phantom_pressed() -> void:
	if not SaveManager.is_ship_unlocked("phantom"):
		_open_buy_popup("phantom", "Phantom", PHANTOM_COST)
		return
	SaveManager.select_ship("phantom")
	update_ui()


func _on_goliath_pressed() -> void:
	if not SaveManager.is_ship_unlocked("goliath"):
		_open_buy_popup("goliath", "Goliath", GOLIATH_COST)
		return
	SaveManager.select_ship("goliath")
	update_ui()


func _open_buy_popup(ship_id: String, ship_name: String, cost: int) -> void:
	var popup: CanvasLayer = BUY_SHIP_POPUP.instantiate()
	add_child(popup)
	if popup.has_method("setup"):
		popup.setup(ship_id, ship_name, cost, SaveManager.credits >= cost)
	if popup.has_signal("confirmed"):
		popup.confirmed.connect(_on_buy_confirmed)
	if popup.has_signal("popup_closed"):
		popup.popup_closed.connect(_on_popup_closed)


func _on_buy_confirmed(ship_id: String) -> void:
	var cost: int = PHANTOM_COST if ship_id == "phantom" else GOLIATH_COST
	if not SaveManager.spend_credits(cost):
		return
	SaveManager.unlock_ship(ship_id)
	_show_info("Куплено!", SaveManager.get_ship_name(ship_id) + " теперь доступен!")
	update_ui()


# ============== ПОКУПКА КОРАБЛЕЙ (МАГАЗИН) ==============

func _on_phantom_buy_pressed() -> void:
	_buy_ship("phantom", PHANTOM_COST)


func _on_goliath_buy_pressed() -> void:
	_buy_ship("goliath", GOLIATH_COST)


func _buy_ship(ship_id: String, cost: int) -> void:
	if SaveManager.is_ship_unlocked(ship_id):
		return
	if not SaveManager.spend_credits(cost):
		return
	SaveManager.unlock_ship(ship_id)
	_show_info("Куплено!", "%s теперь доступен!" % SaveManager.get_ship_name(ship_id))
	update_ui()


# ============== HP УЛУЧШЕНИЕ (МАГАЗИН) ==============

func _on_health_buy_pressed() -> void:
	if SaveManager.health_upgrade_level >= HEALTH_MAX_LEVEL:
		_show_info("Максимум", "HP уже максимального уровня!")
		return
	var cost: int = HEALTH_BASE_COST * int(pow(HEALTH_COST_MULTIPLIER, SaveManager.health_upgrade_level))
	if not SaveManager.spend_credits(cost):
		_show_info("Недостаточно кредитов", "Нужно %d для улучшения HP." % cost)
		return
	SaveManager.health_upgrade_level += 1
	SaveManager.save_game()
	_show_info("Улучшено!", "HP увеличен до уровня %d" % SaveManager.health_upgrade_level)
	update_ui()


# ============== СУНДУКИ ==============

func _on_chest_pressed() -> void:
	_last_chest_type = "module"
	_is_opening_again = false
	_open_module_chest()

func _on_module_chest_pressed() -> void:
	_last_chest_type = "module"
	_open_module_chest()

# Веса для rarity (определяются из .tres файла модуля)
const RARITY_WEIGHTS: Dictionary = {
	"common": 40,    # 40%   (4 модуля: shotgun, rocket, shield, drone → 10% каждая)
	"rare": 32,      # 32%   (6 модулей: laser_mk2, turbo, forsage, composite_armor, rocket_mk2, drone_rare → ~5.33% каждый)
	"epic": 20,      # 20%   (8 модулей: laser_pierce, rocket_homing, shotgun_pressure, diffusor, tactical_accelerator, shockwave, nanobots, drone_epic → 2.5% каждый)
	"legendary": 8   # 8%    (4 модуля: laser_plasma, shotgun_heavy, cocoon_shield, drone_legendary → 2% каждый)
}

# Кеш rarity для модулей (чтобы не грузить .tres каждый раз)
var _module_rarity_cache: Dictionary = {}

func _get_module_rarity(module_id: String) -> String:
	if _module_rarity_cache.has(module_id):
		return _module_rarity_cache[module_id]
	
	var path: String = MODULE_PATHS.get(module_id, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		_module_rarity_cache[module_id] = "common"
		return "common"
	
	var res: Resource = load(path)
	if res == null or not "rarity" in res:
		_module_rarity_cache[module_id] = "common"
		return "common"
	
	var rar: String = str(res.rarity)
	_module_rarity_cache[module_id] = rar
	return rar


func _roll_weighted_module() -> String:
	# Группируем модули по rarity
	var groups: Dictionary = {}  # rarity -> [module_ids]
	for mid in MODULE_CHEST_POOL:
		var rar := _get_module_rarity(mid)
		if not groups.has(rar):
			groups[rar] = []
		groups[rar].append(mid)
	
	# Выбираем rarity по весам
	var total_weight := 0
	for rar in groups:
		total_weight += RARITY_WEIGHTS.get(rar, 10)
	
	var roll := randi() % total_weight
	var cumulative := 0
	var chosen_rarity: String = "common"
	for rar in groups:
		cumulative += RARITY_WEIGHTS.get(rar, 10)
		if roll < cumulative:
			chosen_rarity = rar
			break
	
	# Выбираем случайный модуль из выбранной редкости
	var pool: Array = groups[chosen_rarity]
	return pool[randi() % pool.size()]


func _open_module_chest() -> void:
	_last_chest_type = "module"
	if not SaveManager.spend_credits(MODULE_CHEST_COST):
		_show_info("Недостаточно кредитов", "Нужно %d для открытия сундука модулей." % MODULE_CHEST_COST)
		return
	var rolled_module: String = _roll_weighted_module()
	var is_new := SaveManager.add_module(rolled_module)
	
	# Считаем прогресс: сколько уникальных модулей из пула уже есть
	var obtained := 0
	for mid in MODULE_CHEST_POOL:
		if SaveManager.owned_modules.has(mid) and int(SaveManager.owned_modules[mid]) > 0:
			obtained += 1
	var total := MODULE_CHEST_POOL.size()
	
	if is_new:
		var module_resource: Resource = load(MODULE_PATHS[rolled_module])
		var module_type: String = ""
		if module_resource != null and "type" in module_resource:
			module_type = str(module_resource.type)
		if not module_type.is_empty() and SaveManager.get_equipped_in_slot(module_type).is_empty():
			SaveManager.equip_module(module_type, rolled_module)
		_show_chest_result(rolled_module, true, 0, false, obtained, total)
	else:
		SaveManager.add_credits(MODULE_CHEST_DUPLICATE_COMPENSATION)
		_show_chest_result(rolled_module, false, MODULE_CHEST_DUPLICATE_COMPENSATION, false, obtained, total)
	SaveManager.on_chest_opened()
	SaveManager.on_achievement_progress_check()
	update_ui()


func _on_skin_chest_pressed() -> void:
	_last_chest_type = "skin"
	# Если уже есть открытое окно сундука — не открываем новое (кроме "Открыть ещё")
	if has_node("ChestOpen") and not _is_opening_again:
		return
	_is_opening_again = false
	if not SaveManager.spend_credits(SKIN_CHEST_COST):
		_show_info("Недостаточно кредитов", "Нужно %d для открытия сундука скинов." % SKIN_CHEST_COST)
		return
	# Выбираем случайный скин из пула
	var all_skins: Array = SaveManager.SKIN_CHEST_POOL.duplicate()
	var rolled_skin: String = all_skins[randi() % all_skins.size()]
	
	# Извлекаем ship_id и skin_index
	var parts := rolled_skin.split("_")
	var ship_id := parts[1]
	var skin_index := int(parts[2])
	
	# Пытаемся разблокировать — unlock_skin возвращает false если уже есть
	var is_new := SaveManager.unlock_skin(ship_id, skin_index)
	
	# Считаем прогресс ПОСЛЕ разблокировки: сколько скинов из пула уже открыто
	var obtained := 0
	for sid in SaveManager.SKIN_CHEST_POOL:
		var skin_parts: PackedStringArray = sid.split("_")
		if SaveManager.is_skin_unlocked(skin_parts[1], int(skin_parts[2])):
			obtained += 1
	var total := SaveManager.SKIN_CHEST_POOL.size()
	
	if is_new:
		# Если скин для текущего корабля — автоматом экипируем его
		if ship_id == SaveManager.current_ship:
			SaveManager.select_skin(ship_id, skin_index)
		_show_chest_result(rolled_skin, true, 0, true, obtained, total)
	else:
		SaveManager.add_credits(SKIN_CHEST_DUPLICATE_COMPENSATION)
		_show_chest_result(rolled_skin, false, SKIN_CHEST_DUPLICATE_COMPENSATION, true, obtained, total)
	SaveManager.on_chest_opened()
	SaveManager.on_achievement_progress_check()
	update_ui()
	# После закрытия окна сундука — открываем окно выбора скинов
	# ждём пока popup_closed сработает


# ============== ВЫБОР МОДУЛЯ/СКИНА ==============

func _open_module_select(slot: String) -> void:
	# Добавляем в owned_modules только разблокированные скины
	for ship_id in ["vanguard", "phantom", "goliath"]:
		var unlocked_skins := SaveManager.get_unlocked_skins(ship_id)
		for skin_idx in unlocked_skins:
			var mid: String = "skin_%s_%d" % [ship_id, skin_idx]
			if not SaveManager.owned_modules.has(mid):
				SaveManager.owned_modules[mid] = 1
	SaveManager.save_game()
	var popup: CanvasLayer = MODULE_SELECT_SCENE.instantiate()
	add_child(popup)
	if popup.has_method("setup"):
		popup.setup(slot)
	if popup.has_signal("module_selected"):
		popup.module_selected.connect(_on_module_selected.bind(slot))
	if popup.has_signal("popup_closed"):
		popup.popup_closed.connect(_on_popup_closed)


func _on_module_selected(module_id: String, slot: String) -> void:
	SaveManager.equip_module(slot, module_id)
	update_ui()


func _on_popup_closed() -> void:
	update_ui()


# ============== REAL MONEY SHOP (Yandex Payments) ==============

func _refresh_iap_buttons() -> void:
	if iap_all_modules_btn:
		if SaveManager.all_modules_purchased:
			iap_all_modules_btn.text = "Все модули ✓ Куплено"
			iap_all_modules_btn.disabled = true
			iap_all_modules_btn.modulate = Color(0.7, 0.7, 0.7, 0.6)
		else:
			iap_all_modules_btn.text = "Купить все модули + скины"
			iap_all_modules_btn.disabled = false
			iap_all_modules_btn.modulate = Color(1, 1, 1, 1)
	
	if iap_remove_ads_btn:
		iap_remove_ads_btn.visible = false
		iap_remove_ads_btn.disabled = true


func _on_iap_all_modules_pressed() -> void:
	var ads = get_node_or_null("/root/AdsManager") as Node
	if ads == null or not ads.has_method("purchase_all_modules"):
		return
	
	iap_all_modules_btn.disabled = true
	iap_all_modules_btn.text = "Подключение к магазину..."
	
	var inited = await ads.payments_init()
	if not inited:
		iap_all_modules_btn.text = "Ошибка подключения"
		iap_all_modules_btn.disabled = false
		return
	
	iap_all_modules_btn.text = "Покупка..."
	await ads.purchase_all_modules()
	
	_refresh_iap_buttons()
	update_ui()


func _on_iap_remove_ads_pressed() -> void:
	var ads = get_node_or_null("/root/AdsManager") as Node
	if ads == null or not ads.has_method("purchase_remove_ads"):
		return
	
	iap_remove_ads_btn.disabled = true
	iap_remove_ads_btn.text = "Подключение к магазину..."
	
	var inited = await ads.payments_init()
	if not inited:
		iap_remove_ads_btn.text = "Ошибка подключения"
		iap_remove_ads_btn.disabled = false
		return
	
	iap_remove_ads_btn.text = "Покупка..."
	await ads.purchase_remove_ads()
	
	_refresh_iap_buttons()
	update_ui()


# ============== ОТКРЫТИЕ СУНДУКА (ВИЗУАЛ) ==============

func _show_chest_result(module_id: String, is_new: bool, compensation: int, is_skin: bool = false, obtained_count: int = 0, total_count: int = 0) -> void:
	var popup: CanvasLayer = CHEST_OPEN_SCENE.instantiate()
	add_child(popup)
	if popup.has_method("setup"):
		popup.setup(module_id, is_new, compensation, obtained_count, total_count)
	if popup.has_signal("popup_closed"):
		popup.popup_closed.connect(_on_popup_closed)
	if popup.has_signal("opened_again_requested"):
		if not popup.opened_again_requested.is_connected(_on_chest_again):
			popup.opened_again_requested.connect(_on_chest_again)


func _on_chest_again() -> void:
	# Ставим флаг, чтобы _on_skin_chest_pressed / _on_chest_pressed пропустили проверку has_node
	_is_opening_again = true
	if _last_chest_type == "skin":
		_on_skin_chest_pressed()
	else:
		_on_chest_pressed()


# ============== ИНФО ПОПАП ==============

func _show_info(title: String, message: String) -> void:
	var overlay := CanvasLayer.new()
	overlay.process_mode = PROCESS_MODE_ALWAYS
	add_child(overlay)
	
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.size = get_viewport_rect().size
	dim.anchors_preset = Control.PRESET_FULL_RECT
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)
	
	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.position = Vector2(get_viewport_rect().size.x / 2 - 150, get_viewport_rect().size.y / 2 - 100)
	title_label.size = Vector2(300, 60)
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	overlay.add_child(title_label)
	
	var msg_label := Label.new()
	msg_label.text = message
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.position = Vector2(get_viewport_rect().size.x / 2 - 150, get_viewport_rect().size.y / 2 - 30)
	msg_label.size = Vector2(300, 80)
	msg_label.add_theme_font_size_override("font_size", 24)
	msg_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	overlay.add_child(msg_label)
	
	var ok_btn := Button.new()
	ok_btn.text = "OK"
	ok_btn.position = Vector2(get_viewport_rect().size.x / 2 - 100, get_viewport_rect().size.y / 2 + 60)
	ok_btn.size = Vector2(200, 70)
	ok_btn.add_theme_font_size_override("font_size", 28)
	ok_btn.pressed.connect(func():
		overlay.queue_free()
		update_ui()
	)
	overlay.add_child(ok_btn)
	
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.0, 0.0, 0.0, 0.7)
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_left = 6
	normal.corner_radius_bottom_right = 6
	ok_btn.add_theme_stylebox_override("normal", normal)
	ok_btn.add_theme_stylebox_override("hover", normal)
	ok_btn.add_theme_stylebox_override("pressed", normal)
	ok_btn.add_theme_color_override("font_color", Color.WHITE)


# ============== КНОПКИ ДЕЙСТВИЙ ==============

func _on_play_pressed() -> void:
	var popup = DIFFICULTY_SELECT_SCENE.instantiate()
	add_child(popup)
	if popup.has_signal("difficulty_selected"):
		popup.difficulty_selected.connect(_on_difficulty_selected)
	if popup.has_signal("popup_closed"):
		popup.popup_closed.connect(_on_difficulty_popup_closed)


func _on_difficulty_selected(difficulty: int) -> void:
	get_tree().change_scene_to_file("res://levels/Main.tscn")


func _on_difficulty_popup_closed() -> void:
	update_ui()


func _on_rewards_pressed() -> void:
	var achievements_popup = preload("res://ui/popups/AchievementsList.tscn").instantiate()
	achievements_popup.popup_closed.connect(_on_popup_closed)
	add_child(achievements_popup)


func _on_weapon_slot_pressed() -> void:
	_open_module_select("weapon")


func _on_defense_slot_pressed() -> void:
	_open_module_select("defense")


func _on_utility_slot_pressed() -> void:
	_open_module_select("utility")


# ============== СКИН ПРЕВЬЮ ==============

func _setup_skin_button(btn: ModuleButton) -> void:
	btn.custom_minimum_size = Vector2(70, 70)
	btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.anchors_preset = Control.PRESET_FULL_RECT
	btn.grow_horizontal = Control.GROW_DIRECTION_BOTH
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.position = Vector2.ZERO


func _get_or_create_skin_button(ship_id: String, parent: Node) -> ModuleButton:
	match ship_id:
		"vanguard":
			if _vanguard_skin_btn == null:
				_vanguard_skin_btn = MODULE_BUTTON_SCENE.instantiate()
				_setup_skin_button(_vanguard_skin_btn)
				parent.add_child(_vanguard_skin_btn)
			return _vanguard_skin_btn
		"phantom":
			if _phantom_skin_btn == null:
				_phantom_skin_btn = MODULE_BUTTON_SCENE.instantiate()
				_setup_skin_button(_phantom_skin_btn)
				parent.add_child(_phantom_skin_btn)
			return _phantom_skin_btn
		"goliath":
			if _goliath_skin_btn == null:
				_goliath_skin_btn = MODULE_BUTTON_SCENE.instantiate()
				_setup_skin_button(_goliath_skin_btn)
				parent.add_child(_goliath_skin_btn)
			return _goliath_skin_btn
	return null


func _update_skin_icons() -> void:
	var ships: Array[String] = ["vanguard", "phantom", "goliath"]
	var preview_nodes: Array[Control] = [vanguard_skin_preview, phantom_skin_preview, goliath_skin_preview]
	
	for i in range(3):
		var ship_id: String = ships[i]
		var parent: Control = preview_nodes[i]
		if parent == null:
			continue
		var btn: ModuleButton = _get_or_create_skin_button(ship_id, parent)
		var skin_idx: int = SaveManager.get_current_skin(ship_id)
		btn.setup("skin_%s_%d" % [ship_id, skin_idx])
		btn.custom_minimum_size = Vector2(70, 70)


# ============== СТИЛИЗАЦИЯ ==============

func _set_button_active(btn: Button, active: bool) -> void:
	if btn == null:
		return
	if active:
		var active_style := StyleBoxFlat.new()
		active_style.bg_color = Color(0.15, 0.25, 0.45, 0.9)
		active_style.corner_radius_top_left = 6
		active_style.corner_radius_top_right = 6
		active_style.corner_radius_bottom_left = 6
		active_style.corner_radius_bottom_right = 6
		active_style.content_margin_left = 8
		active_style.content_margin_right = 8
		active_style.content_margin_top = 4
		active_style.content_margin_bottom = 4
		btn.add_theme_stylebox_override("normal", active_style)
		btn.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0, 1))
	else:
		_apply_button_style(btn)


func _apply_styles_to_all_buttons() -> void:
	_apply_button_style(play_button)
	_apply_button_style(shop_button)
	if rewards_button:
		_apply_button_style(rewards_button)
	_apply_button_style(vanguard_button)
	_apply_button_style(phantom_button)
	_apply_button_style(goliath_button)
	_apply_button_style(weapon_slot)
	_apply_button_style(defense_slot)
	_apply_button_style(utility_slot)
	_apply_button_style(chest_button)
	_apply_button_style(skin_slot_button)
	# Магазин — кнопки с голубой рамкой
	if phantom_buy_button: _apply_shop_button_style(phantom_buy_button)
	if goliath_buy_button: _apply_shop_button_style(goliath_buy_button)
	if health_buy_button: _apply_shop_button_style(health_buy_button)
	if module_chest_button: _apply_shop_button_style(module_chest_button)
	if skin_chest_button: _apply_shop_button_style(skin_chest_button)


func _apply_shop_button_style(btn: Button) -> void:
	if btn == null:
		return
	# Сначала базовая стилизация
	_apply_button_style(btn)
	
	var border_color := Color(0.3, 0.6, 1.0, 0.8)  # голубая рамка
	
	# Normal — с рамкой
	var normal := btn.get_theme_stylebox("normal")
	if normal is StyleBoxFlat:
		normal.border_width_left = 2
		normal.border_width_right = 2
		normal.border_width_top = 2
		normal.border_width_bottom = 2
		normal.border_color = border_color
	
	# Hover — рамка ярче
	var hover := btn.get_theme_stylebox("hover")
	if hover is StyleBoxFlat:
		hover.border_width_left = 2
		hover.border_width_right = 2
		hover.border_width_top = 2
		hover.border_width_bottom = 2
		hover.border_color = Color(0.5, 0.8, 1.0, 1.0)
	
	# Pressed — рамка тусклее
	var pressed := btn.get_theme_stylebox("pressed")
	if pressed is StyleBoxFlat:
		pressed.border_width_left = 2
		pressed.border_width_right = 2
		pressed.border_width_top = 2
		pressed.border_width_bottom = 2
		pressed.border_color = Color(0.2, 0.4, 0.7, 1.0)
	
	# Disabled (если есть) — совсем тусклая рамка
	if btn.has_theme_stylebox_override("disabled"):
		var disabled := btn.get_theme_stylebox("disabled")
		if disabled is StyleBoxFlat:
			disabled.border_width_left = 1
			disabled.border_width_right = 1
			disabled.border_width_top = 1
			disabled.border_width_bottom = 1
			disabled.border_color = Color(0.2, 0.3, 0.5, 0.4)


func _apply_button_style(btn: Button, custom_height: int = 64) -> void:
	if btn == null:
		return
	
	var alpha_val: float = 188.0 / 255.0
	
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.0, 0.0, 0.0, alpha_val)
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_left = 6
	normal.corner_radius_bottom_right = 6
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 4
	normal.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", normal)
	
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.1, 0.1, 0.15, alpha_val)
	hover.corner_radius_top_left = 6
	hover.corner_radius_top_right = 6
	hover.corner_radius_bottom_left = 6
	hover.corner_radius_bottom_right = 6
	hover.content_margin_left = 8
	hover.content_margin_right = 8
	hover.content_margin_top = 4
	hover.content_margin_bottom = 4
	btn.add_theme_stylebox_override("hover", hover)
	
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(0.05, 0.05, 0.1, alpha_val)
	pressed.corner_radius_top_left = 6
	pressed.corner_radius_top_right = 6
	pressed.corner_radius_bottom_left = 6
	pressed.corner_radius_bottom_right = 6
	pressed.content_margin_left = 8
	pressed.content_margin_right = 8
	pressed.content_margin_top = 4
	pressed.content_margin_bottom = 4
	btn.add_theme_stylebox_override("pressed", pressed)
	
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color(0.9, 0.9, 0.95, 1))
	
	if custom_height <= 48:
		normal.content_margin_left = 0
		normal.content_margin_right = 0
		normal.content_margin_top = 0
		normal.content_margin_bottom = 0
		hover.content_margin_left = 0
		hover.content_margin_right = 0
		hover.content_margin_top = 0
		hover.content_margin_bottom = 0
		pressed.content_margin_left = 0
		pressed.content_margin_right = 0
		pressed.content_margin_top = 0
		pressed.content_margin_bottom = 0
		btn.add_theme_font_size_override("font_size", 24)


# ============== АУДИО ==============

func _setup_audio_buttons() -> void:
	settings_btn = Button.new()
	settings_btn.name = "SettingsBtn"
	settings_btn.text = "="
	settings_btn.custom_minimum_size = Vector2(64, 64)
	settings_btn.size = Vector2(64, 64)
	settings_btn.position = Vector2(16, 16)
	settings_btn.pressed.connect(_on_settings_pressed)
	add_child(settings_btn)

	music_toggle_btn = TextureButton.new()
	music_toggle_btn.texture_normal = load("res://assets/icons/music.png")
	music_toggle_btn.name = "MusicToggleBtn"
	music_toggle_btn.custom_minimum_size = Vector2(64, 64)
	music_toggle_btn.size = Vector2(64, 64)
	music_toggle_btn.position = Vector2(720 - 64 - 16 - 80, 16)
	music_toggle_btn.pressed.connect(_on_music_toggle)
	add_child(music_toggle_btn)

	sfx_toggle_btn = TextureButton.new()
	sfx_toggle_btn.texture_normal = load("res://assets/icons/sound.png")
	sfx_toggle_btn.name = "SfxToggleBtn"
	sfx_toggle_btn.custom_minimum_size = Vector2(64, 64)
	sfx_toggle_btn.size = Vector2(64, 64)
	sfx_toggle_btn.position = Vector2(720 - 64 - 16, 16)
	sfx_toggle_btn.pressed.connect(_on_sfx_toggle)
	add_child(sfx_toggle_btn)

	_apply_button_style(settings_btn, 64)
	_sync_audio_buttons()


func _sync_audio_buttons() -> void:
	var am := get_node_or_null("/root/AudioManager") as Node
	if am == null:
		return
	_prev_music_volume = am.music_volume
	_prev_sfx_volume = am.sfx_volume
	_update_audio_button_texts()


func _update_audio_button_texts() -> void:
	var am := get_node_or_null("/root/AudioManager") as Node
	if am == null:
		return
	if music_toggle_btn:
		music_toggle_btn.modulate = Color(1, 1, 1, 1) if am.music_volume > 0.0 else Color(0.3, 0.3, 0.3, 0.5)
	if sfx_toggle_btn:
		sfx_toggle_btn.modulate = Color(1, 1, 1, 1) if am.sfx_volume > 0.0 else Color(0.3, 0.3, 0.3, 0.5)


func _on_music_toggle() -> void:
	var am := get_node_or_null("/root/AudioManager") as Node
	if am:
		if am.music_volume > 0.0:
			_prev_music_volume = am.music_volume
			am.set_music_volume(0.0)
		else:
			am.set_music_volume(_prev_music_volume)
		_update_audio_button_texts()


func _on_sfx_toggle() -> void:
	var am := get_node_or_null("/root/AudioManager") as Node
	if am:
		if am.sfx_volume > 0.0:
			_prev_sfx_volume = am.sfx_volume
			am.set_sfx_volume(0.0)
		else:
			am.set_sfx_volume(_prev_sfx_volume)
		_update_audio_button_texts()


func _on_settings_pressed() -> void:
	var popup := load("res://ui/popups/AudioSettingsPopup.tscn")
	if popup == null:
		var inst = load("res://ui/popups/AudioSettingsPopup.gd").new()
		add_child(inst)
		inst.popup_closed.connect(_on_audio_settings_closed)
	else:
		var inst = popup.instantiate()
		add_child(inst)
		if inst.has_signal("popup_closed"):
			inst.popup_closed.connect(_on_audio_settings_closed)


func _on_audio_settings_closed() -> void:
	_sync_audio_buttons()
