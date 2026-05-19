@tool
class_name TiDePropertyElement
extends Control


@export var _property_title_value: TiDeTitleValuePair

@export_group("Snapshots Refs")
@export var _snapshots_foldout: FoldableContainer
@export var _min_value: TiDeTitleValuePair
@export var _max_value: TiDeTitleValuePair
@export var _average_value: TiDeTitleValuePair


var custom_id: String

var _value: String


func setup(p_custom_id: String, p_value: String) -> void:
	custom_id = p_custom_id
	_property_title_value.set_title(p_custom_id.split("::")[1])
	_value = p_value
	_property_title_value.set_value(p_value)
	
	_snapshots_foldout.folded = true


func update(p_value: String) -> void:
	_value = p_value
	_property_title_value.set_value(p_value)
