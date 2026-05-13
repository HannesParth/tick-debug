@tool
class_name TiDePropertyElement
extends Control


@export var _name_label: Label
@export var _value_label: Label


var custom_id: String

var _value: Variant


func setup(p_custom_id: String, p_value: Variant) -> void:
	custom_id = p_custom_id
	_name_label.text = p_custom_id.split("::")[1]
	_value = p_value
	_value_label.text = str(_value)


func update(p_value: Variant) -> void:
	_value = p_value
	_value_label.text = str(_value) if p_value != null else "NULL"
