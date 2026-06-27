extends Resource
class_name ModuleVisuals

## Конфиг визуала кнопки модуля. Один ресурс на модуль (или общий default).
## Поля задаются прямо в инспекторе — никакого кода для правки внешнего вида.

@export var button_size: Vector2 = Vector2(64, 64)

## Статическая иконка (Texture2D). Используется, если icon_animated_frames не задан.
@export var icon_texture: Texture2D
@export var icon_scale: float = 1.0
@export var icon_offset: Vector2 = Vector2.ZERO

## Анимированная иконка (SpriteFrames). Если задана — она используется вместо icon_texture.
## Позволяет делать крутящиеся/мигающие иконки модулей.
@export var icon_animated_frames: SpriteFrames
@export var icon_animated_speed: float = 1.0
@export var icon_animated_name: String = "default"

## Опциональная фоновая анимация (SpriteFrames). Если null — фон пустой.
@export var background_frames: SpriteFrames
@export var background_speed: float = 10.0
@export var background_offset: Vector2 = Vector2.ZERO

## Цвета состояний — мультиплицируются поверх иконки/фона.
@export var normal_color: Color = Color(1, 1, 1, 1)
@export var hover_color: Color = Color(1.15, 1.15, 1.15, 1)
@export var pressed_color: Color = Color(0.85, 0.85, 0.85, 1)
@export var disabled_color: Color = Color(0.6, 0.6, 0.6, 0.8)
@export var selected_color: Color = Color(1.2, 1.1, 0.6, 1)

## Рамка/подсветка редкости. Если null — не рисуется.
@export var rarity_frame: Texture2D
@export var rarity_color: Color = Color(1, 1, 1, 1)

## Текст fallback'а, если иконки нет. Пусто — пусто.
@export var fallback_text: String = ""

## Ссылка на готовую сцену скина (.tscn).
## Если задана — используется для instantiate скина в игре вместо hardcoded узлов.
## Позволяет визуально редактировать скин в отдельной сцене
## и настраивать position, z_index, анимации и дополнительные эффекты.
@export var skin_scene: PackedScene

## Путь к иконке по convention. Используется ModuleButton, если icon_texture не задан.
@export var icon_path_convention: String = "res://assets/sprites/ui/moduls/{id}.png"


static func get_default_path() -> String:
	return "res://data/visuals/default_module_visuals.tres"


static func get_path_for(module_id: String) -> String:
	return "res://data/visuals/%s_visuals.tres" % module_id
