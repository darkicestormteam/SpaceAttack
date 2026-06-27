extends Node

## Autoload: выставляет autowrap_mode = 3 (Word/Smart) всем Label/RichTextLabel/Button
## в момент их добавления в дерево сцены.
## Подключается автоматически — нужно зарегистрировать в project.godot как autoload
## с именем `AutoWrap` и путём `*res://project_root/autoloads/AutoWrap.gd`.

const AUTOWRAP_WORD_SMART: int = 3  # TextServer.AUTOWRAP_WORD_SMART

var _tree: SceneTree = null


func _enter_tree() -> void:
	# Autoload подключается к SceneTree раньше, чем любые сцены.
	_tree = get_tree()
	if _tree != null:
		_tree.node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node is Label:
		(node as Label).autowrap_mode = AUTOWRAP_WORD_SMART
	elif node is RichTextLabel:
		(node as RichTextLabel).autowrap_mode = AUTOWRAP_WORD_SMART
	# Button text тоже наследуется от BaseButton, но autowrap_mode — специфичен для Label.
