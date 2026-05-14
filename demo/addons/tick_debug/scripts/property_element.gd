@tool
class_name TiDePropertyElement
extends Control


@export var _name_label: Label
@export var _value_label: Label


var custom_id: String

var _value: String


func setup(p_custom_id: String, p_value: String) -> void:
	custom_id = p_custom_id
	_name_label.text = p_custom_id.split("::")[1]
	_value = p_value
	_value_label.text = p_value


func update(p_value: String) -> void:
	_value = p_value
	_value_label.text = p_value
