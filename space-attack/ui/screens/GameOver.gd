extends CanvasLayer

## Экран поражения (без рекламы).

@onready var score_label: Label = %ScoreLabel
@onready var credits_label: Label = %CreditsLabel
@onready var restart_btn: Button = %RestartButton
@onready var quit_btn: Button = %QuitButton
@onready var revive_btn: Button = %ReviveButton

var _credits_earned: int = 0
var _has_revived: bool = false
var _is_action_pending: bool = false


func _ready() -> void:
	restart_btn.pressed.connect(_on_restart_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	revive_btn.pressed.connect(_on_revive_pressed)


func set_stats(final_score: int, final_credits: int, earned: int = 0) -> void:
	score_label.text = "Очки: " + str(final_score)
	_credits_earned = earned
	credits_label.text = "Заработано кредитов: " + str(_credits_earned)


# ============================================================
# Воскрешение (бесплатно, без рекламы)
# ============================================================

func _on_revive_pressed() -> void:
	if _has_revived or _is_action_pending:
		return
	_is_action_pending = true
	
	revive_btn.disabled = true
	
	_has_revived = true
	var main = get_tree().current_scene
	if main and main.has_method("revive_player"):
		main.revive_player()
	
	_is_action_pending = false


# ============================================================
# "Заново" — просто рестарт
# ============================================================

func _on_restart_pressed() -> void:
	if _is_action_pending:
		return
	_is_action_pending = true
	
	get_tree().paused = false
	get_tree().reload_current_scene()


# ============================================================
# "Выход" — просто в ангар
# ============================================================

func _on_quit_pressed() -> void:
	if _is_action_pending:
		return
	_is_action_pending = true
	
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/screens/Hangar.tscn")
