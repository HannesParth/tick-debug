@tool
class_name TiDeTitleValuePair
extends HBoxContainer


@export var _title_label: Label
@export var _value_label: Label

@export var _default_title: String:
	set(value):
		_title_label.text = value
		_default_title = value
	get:
		return _title_label.text
@export var _default_value: String:
	set(value):
		_value_label.text = value
		_default_value = value
	get:
		return _value_label.text

var _raw_value: Variant


func set_title(p_text: String) -> void:
	_title_label.text = p_text


## Sets the Value Label of this pair if it is different from the
## previous value. [br]
## If the value is not a String, uses [method TickDebug._format_value].
func set_value(p_value: Variant) -> void:
	if _raw_value == p_value: 
		return
	
	if p_value is String:
		_value_label.text = p_value
	else:
		_value_label.text = TickDebug._format_value(p_value)
