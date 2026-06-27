extends Node2D

## Фейковый параллакс для корабля.
## Все дочерние узлы (спрайты и маркеры) двигаются вниз.
## При достижении 1810 телепортируются на -1040.

@export var scroll_speed: float = 50.0
@export var cannon_scene: PackedScene

## Анимация при активации (проигрывается после включения)
@export var activate_animation: String = "run"
## Анимация при деактивации (проигрывается перед выключением)
@export var deactivate_animation: String = ""

class _TurretSlot:
	var marker: Marker2D
	var turret: Node2D = null

var _slots: Array[_TurretSlot] = []
var _move_nodes: Array[Node2D] = []
var _animation_player: AnimationPlayer = null
var _is_active: bool = false


func _ready() -> void:
	for child in get_children():
		if child is Node2D:
			_move_nodes.append(child)
	
	_animation_player = get_node_or_null("AnimationPlayer") as AnimationPlayer
	
	_scan_markers()
	_spawn_all_turrets()
	
	_set_enabled(false)


func _set_enabled(flag: bool) -> void:
	_is_active = flag
	set_process(flag)
	set_physics_process(flag)
	visible = flag
	
	if flag:
		_scan_markers()
		_spawn_all_turrets()
	else:
		for slot in _slots:
			if slot.turret and is_instance_valid(slot.turret):
				slot.turret.queue_free()
			slot.turret = null
		_slots.clear()


func activate() -> void:
	_set_enabled(true)
	if _animation_player and activate_animation and _animation_player.has_animation(activate_animation):
		_animation_player.play(activate_animation)
		await _animation_player.animation_finished


func deactivate() -> void:
	if _animation_player and deactivate_animation and _animation_player.has_animation(deactivate_animation):
		_animation_player.play(deactivate_animation)
		await _animation_player.animation_finished
	_set_enabled(false)


func _scan_markers() -> void:
	for child in get_children():
		if child is Marker2D:
			var slot := _TurretSlot.new()
			slot.marker = child
			_slots.append(slot)


func _spawn_all_turrets() -> void:
	if not cannon_scene:
		return
	for slot in _slots:
		_spawn_turret(slot)


func _spawn_turret(slot: _TurretSlot) -> void:
	if not cannon_scene or not slot.marker:
		return
	if slot.turret and is_instance_valid(slot.turret):
		slot.turret.queue_free()
		slot.turret = null
	
	var turret: Node2D = cannon_scene.instantiate()
	slot.marker.add_child(turret)
	turret.position = Vector2.ZERO
	slot.turret = turret


func _process(delta: float) -> void:
	if _move_nodes.is_empty():
		return
	
	var move_y: float = scroll_speed * delta
	
	for node in _move_nodes:
		node.position.y += move_y
		
		if node.position.y > 1810.0:
			node.position.y -= 2850.0
			
			for slot in _slots:
				if slot.marker == node:
					_spawn_turret(slot)
					break