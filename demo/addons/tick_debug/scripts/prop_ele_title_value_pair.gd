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


func set_title(p_text: String) -> void:
	_title_label.text = p_text


func set_value(p_text: String) -> void:
	_value_label.text = p_text
