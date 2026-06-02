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


func setup(p_custom_id: String, p_data: TickDebug.ValueData) -> void:
	custom_id = p_custom_id
	
	_property_title_value.set_title(p_custom_id.split("::")[1])
	update(p_data)
	
	_snapshots_foldout.folded = true


func update(p_data: TickDebug.ValueData) -> void:
	_property_title_value.set_value(p_data.value)
	_min_value.set_value(p_data.min_value)
	_max_value.set_value(p_data.max_value)
	_average_value.set_value(p_data.average)
