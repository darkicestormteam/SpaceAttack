extends CanvasLayer

signal confirmed(ship_id: String)
signal popup_closed

@onready var title_label: Label = %TitleLabel
@onready var msg_label: Label = %MsgLabel
@onready var cost_label: Label = %CostLabel
@onready var yes_button: Button = %YesButton
@onready var no_button: Button = %NoButton
@onready var ok_button: Button = %OkButton

var _ship_id: String = ""

func _ready() -> void:
	yes_button.pressed.connect(_on_yes_pressed)
	no_button.pressed.connect(_on_no_pressed)
	ok_button.pressed.connect(_on_ok_pressed)
	_setup_localization()
	if LocalizationManager.language_changed.is_connected(_on_language_changed):
		LocalizationManager.language_changed.disconnect(_on_language_changed)
	LocalizationManager.language_changed.connect(_on_language_changed)


func _setup_localization() -> void:
	ok_button.text = tr("buy_ok")


func _on_language_changed(_locale: String) -> void:
	_setup_localization()


func setup(ship_id: String, ship_name: String, cost: int, can_afford: bool) -> void:
	_ship_id = ship_id
	
	if can_afford:
		title_label.text = tr("ship_name_" + ship_id)
		title_label.show()
		
		cost_label.text = tr("buy_cost") % cost
		cost_label.show()
		
		msg_label.text = ""
		msg_label.show()
		
		yes_button.show()
		no_button.show()
		ok_button.hide()
	else:
		title_label.text = tr("buy_no_credits")
		title_label.show()
		
		cost_label.hide()
		msg_label.hide()
		yes_button.hide()
		no_button.hide()
		ok_button.show()

func _on_yes_pressed() -> void:
	confirmed.emit(_ship_id)
	queue_free()

func _on_no_pressed() -> void:
	popup_closed.emit()
	queue_free()

func _on_ok_pressed() -> void:
	popup_closed.emit()
	queue_free()
