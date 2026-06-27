extends CanvasLayer

signal popup_closed

@onready var title_label: Label = %TitleLabel
@onready var msg_label: Label = %MsgLabel
@onready var ok_button: Button = %OkButton

func _ready() -> void:
	ok_button.pressed.connect(func():
		queue_free()
		popup_closed.emit()
	)

func setup(title: String, message: String) -> void:
	title_label.text = title
	msg_label.text = message
