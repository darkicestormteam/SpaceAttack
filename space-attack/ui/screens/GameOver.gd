extends CanvasLayer

@onready var score_label: Label = %ScoreLabel
@onready var credits_label: Label = %CreditsLabel
@onready var restart_btn: Button = %RestartButton
@onready var quit_btn: Button = %QuitButton


func _ready() -> void:
	restart_btn.pressed.connect(_on_restart_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)


func set_stats(final_score: int, final_credits: int) -> void:
	score_label.text = "Очки: " + str(final_score)
	credits_label.text = "Кредиты: " + str(final_credits)


func _on_restart_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/screens/Hangar.tscn")


func _on_quit_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/screens/Hangar.tscn")
