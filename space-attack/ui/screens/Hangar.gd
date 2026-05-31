extends Control

@onready var credits_label: Label = %CreditsLabel
@onready var high_score_label: Label = %HighScoreLabel
@onready var play_button: Button = %PlayButton
@onready var shop_button: Button = %ShopButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	SaveManager.load_game()
	update_ui()
	
	play_button.pressed.connect(_on_play_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func update_ui() -> void:
	credits_label.text = "⭐ " + str(SaveManager.credits)
	high_score_label.text = "🏆 Лучший счёт: " + str(SaveManager.high_score)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/Main.tscn")


func _on_shop_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/screens/Shop.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
