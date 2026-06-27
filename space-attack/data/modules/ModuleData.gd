extends Resource
class_name ModuleData

## Данные модуля. Поля доступны как экспортируемые — Godot видит их через
## `res.name`, `res.type` и т.д. в коде, и редактируются прямо в инспекторе.
##
## Категория (`type`):
##   "weapon"   — оружие
##   "defense"  — защита
##   "utility"  — утилита

@export var name: String = ""
@export var type: String = "utility"  # weapon | defense | utility
@export var description: String = ""
@export var rarity: String = "common"  # common | rare | epic | legendary
@export var pellet_color: Color = Color.WHITE  # Цвет pellet'ов (только для weapon модулей с дробовиком)

## Бонусы скинов — применяются только для type = "skin"
@export var damage_bonus: int = 0         # + к урону
@export var speed_mult: float = 1.0       # множитель скорости (1.0 = без изменений)
@export var health_bonus: int = 0         # + к максимальному HP
@export var fire_rate_mult: float = 1.0   # множитель скорострельности (меньше = быстрее)
