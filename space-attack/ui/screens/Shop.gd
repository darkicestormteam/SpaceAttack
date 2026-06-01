extends Control

const UPGRADE_COSTS = {
	"damage": [100, 200, 400],
	"fire_rate": [150, 300, 600],
	"health": [200, 400, 800]
}

const SHOCKWAVE_COST: int = 300

@onready var credits_label: Label = $ShopPanel/CreditsLabel
@onready var damage_level_label: Label = $ShopPanel/DamageRow/DamageInfo/DamageLevel
@onready var fire_rate_level_label: Label = $ShopPanel/FireRateRow/FireRateInfo/FireRateLevel
@onready var health_level_label: Label = $ShopPanel/HealthRow/HealthInfo/HealthLevel
@onready var damage_button: Button = $ShopPanel/DamageRow/DamageButton
@onready var fire_rate_button: Button = $ShopPanel/FireRateRow/FireRateButton
@onready var health_button: Button = $ShopPanel/HealthRow/HealthButton
@onready var shockwave_button: Button = %ShockwaveButton
@onready var back_button: Button = $ShopPanel/BackButton


func _ready() -> void:
	SaveManager.load_game()
	update_ui()

	damage_button.pressed.connect(_on_damage_buy_pressed)
	fire_rate_button.pressed.connect(_on_fire_rate_buy_pressed)
	health_button.pressed.connect(_on_health_buy_pressed)
	if shockwave_button:
		shockwave_button.pressed.connect(_on_shockwave_buy_pressed)
	back_button.pressed.connect(_on_back_pressed)


func update_ui() -> void:
	credits_label.text = "⭐ " + str(SaveManager.credits) + " кредитов"
	damage_level_label.text = "Уровень: " + str(SaveManager.damage_upgrade_level) + " / 3"
	fire_rate_level_label.text = "Уровень: " + str(SaveManager.fire_rate_upgrade_level) + " / 3"
	health_level_label.text = "Уровень: " + str(SaveManager.health_upgrade_level) + " / 3"

	_update_button(damage_button, SaveManager.damage_upgrade_level, "damage")
	_update_button(fire_rate_button, SaveManager.fire_rate_upgrade_level, "fire_rate")
	_update_button(health_button, SaveManager.health_upgrade_level, "health")
	_update_shockwave_button()


func _update_button(button: Button, level: int, upgrade: String) -> void:
	var costs = UPGRADE_COSTS[upgrade]
	if level >= costs.size():
		button.text = "Макс."
		button.disabled = true
		return
	var cost = costs[level]
	button.text = str(cost) + " ⭐"
	button.disabled = SaveManager.credits < cost


func _update_shockwave_button() -> void:
	if not shockwave_button:
		return
	if SaveManager.has_module("shockwave"):
		shockwave_button.text = "Куплено"
		shockwave_button.disabled = true
		return
	if SaveManager.credits < SHOCKWAVE_COST:
		shockwave_button.text = str(SHOCKWAVE_COST) + " ⭐"
		shockwave_button.disabled = true
		return
	shockwave_button.text = str(SHOCKWAVE_COST) + " ⭐"
	shockwave_button.disabled = false


func _buy_upgrade(upgrade: String) -> void:
	var costs = UPGRADE_COSTS[upgrade]
	var level: int
	match upgrade:
		"damage":
			level = SaveManager.damage_upgrade_level
		"fire_rate":
			level = SaveManager.fire_rate_upgrade_level
		"health":
			level = SaveManager.health_upgrade_level
		_:
			return

	if level >= costs.size():
		return

	var cost = costs[level]
	if SaveManager.credits < cost:
		return

	SaveManager.credits -= cost
	match upgrade:
		"damage":
			SaveManager.damage_upgrade_level += 1
		"fire_rate":
			SaveManager.fire_rate_upgrade_level += 1
		"health":
			SaveManager.health_upgrade_level += 1

	SaveManager.save_game()
	update_ui()


# Покупка модуля "Импульсная волна" за 300 кредитов.
# При покупке модуль добавляется в owned_modules и экипируется в слот utility.
func _buy_shockwave() -> void:
	if SaveManager.has_module("shockwave"):
		return
	if SaveManager.credits < SHOCKWAVE_COST:
		return
	SaveManager.credits -= SHOCKWAVE_COST
	SaveManager.add_module("shockwave")
	# Если слот utility пуст — автоматически экипируем
	if SaveManager.get_equipped_in_slot("utility").is_empty():
		SaveManager.equip_module("utility", "shockwave")
	SaveManager.save_game()
	update_ui()


func _on_damage_buy_pressed() -> void:
	_buy_upgrade("damage")


func _on_fire_rate_buy_pressed() -> void:
	_buy_upgrade("fire_rate")


func _on_health_buy_pressed() -> void:
	_buy_upgrade("health")


func _on_shockwave_buy_pressed() -> void:
	_buy_shockwave()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/screens/Hangar.tscn")
