extends CanvasLayer

@onready var score_label: Label = $ScoreLabel
@onready var credits_label: Label = $CreditsLabel
@onready var lives_label: Label = $LivesLabel
@onready var wave_label: Label = $WaveLabel


func update_score(value: int) -> void:
	score_label.text = "Очки: " + str(value)


func update_credits(value: int) -> void:
	credits_label.text = "Кредиты: " + str(value)


func update_lives(value: int) -> void:
	var hearts := PackedStringArray()
	for i in range(value):
		hearts.append("❤️")
	lives_label.text = " ".join(hearts)


func update_wave(value: int) -> void:
	wave_label.text = "Wave: " + str(value)
