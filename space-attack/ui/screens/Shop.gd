extends Control

const UPGRADE_COSTS = {
	"damage": [100, 200, 400],
	"fire_rate": [150, 300, 600],
	"health": [200, 400, 800]
}

const MODULE_COST: int = 300
const PHANTOM_COST: int = 2000
const GOLIATH_COST: int = 5000

@onready var credits_label: Label = %CreditsLabel

# Корабли
@onready var phantom_buy_button: Button = %PhantomBuyButton
@onready var goliath_buy_button: Button = %GoliathBuyButton

# Улучшения
@onready var damage_button: Button = %DamageButton
@onready var fire_rate_button: Button = %FireRateButton
@onready var health_button: Button = %HealthButton
@onready var damage_level_label: Label = %DamageLevel
@onready var fire_rate_level_label: Label = %FireRateLevel
@onready var health_level_label: Label = %HealthLevel

# Модули
@onready var shotgun_button: Button = %ShotgunButton
@onready var shield_button: Button = %ShieldButton
@onready var shockwave_button: Button = %ShockwaveButton

@onready var back_button: Button = %BackButton


func _ready() -> void:
	SaveManager.load_game()
	update_ui()

	if phantom_buy_button:
		phantom_buy_button.pressed.connect(_on_phantom_buy_pressed)
	if goliath_buy_button:
		goliath_buy_button.pressed.connect(_on_goliath_buy_pressed)
	if damage_button:
		damage_button.pressed.connect(_on_damage_buy_pressed)
	if fire_rate_button:
		fire_rate_button.pressed.connect(_on_fire_rate_buy_pressed)
	if health_button:
		health_button.pressed.connect(_on_health_buy_pressed)
	if shotgun_button:
		shotgun_button.pressed.connect(_on_shotgun_buy_pressed)
	if shield_button:
		shield_button.pressed.connect(_on_shield_buy_pressed)
	if shockwave_button:
		shockwave_button.pressed.connect(_on_shockwave_buy_pressed)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)


func update_ui() -> void:
	credits_label.text = "⭐ " + str(SaveManager.credits) + " кредитов"

	# Корабли
	_update_ship_button(phantom_buy_button, "phantom", PHANTOM_COST)
	_update_ship_button(goliath_buy_button, "goliath", GOLIATH_COST)

	# Улучшения
	damage_level_label.text = str(SaveManager.damage_upgrade_level) + " / 3"
	fire_rate_level_label.text = str(SaveManager.fire_rate_upgrade_level) + " / 3"
	health_level_label.text = str(SaveManager.health_upgrade_level) + " / 3"
	_update_upgrade_button(damage_button, SaveManager.damage_upgrade_level, "damage")
	_update_upgrade_button(fire_rate_button, SaveManager.fire_rate_upgrade_level, "fire_rate")
	_update_upgrade_button(health_button, SaveManager.health_upgrade_level, "health")

	# Модули
	_update_module_button(shotgun_button, "shotgun", "weapon")
	_update_module_button(shield_button, "shield", "defense")
	_update_shockwave_button()


func _update_ship_button(button: Button, ship_id: String, cost: int) -> void:
	if not button:
		return
	if SaveManager.is_ship_unlocked(ship_id):
		button.text = SaveManager.get_ship_name(ship_id) + " — Куплен"
		button.disabled = true
		return
	if SaveManager.credits < cost:
		button.text = SaveManager.get_ship_name(ship_id) + " — " + str(cost) + "⭐"
		button.disabled = true
		return
	button.text = SaveManager.get_ship_name(ship_id) + " — " + str(cost) + "⭐"
	button.disabled = false


func _update_upgrade_button(button: Button, level: int, upgrade: String) -> void:
	var costs = UPGRADE_COSTS[upgrade]
	if level >= costs.size():
		button.text = "Макс."
		button.disabled = true
		return
	var cost = costs[level]
	button.text = str(cost) + "⭐"
	button.disabled = SaveManager.credits < cost


func _update_module_button(button: Button, module_id: String, _slot: String) -> void:
	if not button:
		return
	if SaveManager.has_module(module_id):
		button.text = "Куплено"
		button.disabled = true
		return
	if SaveManager.credits < MODULE_COST:
		button.text = str(MODULE_COST) + "⭐"
		button.disabled = true
		return
	button.text = str(MODULE_COST) + "⭐"
	button.disabled = false


func _update_shockwave_button() -> void:
	if not shockwave_button:
		return
	if SaveManager.has_module("shockwave"):
		shockwave_button.text = "Куплено"
		shockwave_button.disabled = true
		return
	if SaveManager.credits < MODULE_COST:
		shockwave_button.text = str(MODULE_COST) + "⭐"
		shockwave_button.disabled = true
		return
	shockwave_button.text = str(MODULE_COST) + "⭐"
	shockwave_button.disabled = false


func _buy_ship(ship_id: String, cost: int) -> void:
	if SaveManager.is_ship_unlocked(ship_id):
		return
	if SaveManager.credits < cost:
		return
	SaveManager.credits -= cost
	SaveManager.unlock_ship(ship_id)
	SaveManager.save_game()
	update_ui()


func _buy_upgrade(upgrade: String) -> void:
	var costs = UPGRADE_COSTS[upgrade]
	var level: int
	match upgrade:
		"damage": level = SaveManager.damage_upgrade_level
		"fire_rate": level = SaveManager.fire_rate_upgrade_level
		"health": level = SaveManager.health_upgrade_level
		_: return
	if level >= costs.size():
		return
	var cost = costs[level]
	if SaveManager.credits < cost:
		return
	SaveManager.credits -= cost
	match upgrade:
		"damage": SaveManager.damage_upgrade_level += 1
		"fire_rate": SaveManager.fire_rate_upgrade_level += 1
		"health": SaveManager.health_upgrade_level += 1
	SaveManager.save_game()
	update_ui()


func _buy_module(module_id: String, equip_slot: String) -> void:
	if SaveManager.has_module(module_id):
		return
	if SaveManager.credits < MODULE_COST:
		return
	SaveManager.credits -= MODULE_COST
	SaveManager.add_module(module_id)
	if SaveManager.get_equipped_in_slot(equip_slot).is_empty():
		SaveManager.equip_module(equip_slot, module_id)
	SaveManager.save_game()
	update_ui()


func _on_phantom_buy_pressed() -> void:
	_buy_ship("phantom", PHANTOM_COST)


func _on_goliath_buy_pressed() -> void:
	_buy_ship("goliath", GOLIATH_COST)


func _on_damage_buy_pressed() -> void:
	_buy_upgrade("damage")


func _on_fire_rate_buy_pressed() -> void:
	_buy_upgrade("fire_rate")


func _on_health_buy_pressed() -> void:
	_buy_upgrade("health")


func _on_shotgun_buy_pressed() -> void:
	_buy_module("shotgun", "weapon")


func _on_shield_buy_pressed() -> void:
	_buy_module("shield", "defense")


func _on_shockwave_buy_pressed() -> void:
	_buy_module("shockwave", "utility")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/screens/Hangar.tscn")