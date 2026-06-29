@tool
class_name TiDeGraphSimple
extends Panel
## A simpel 2D line graph specialized for working with [TickDebug.ValueData].


const LINE_COLOR: Color = Color.LIME_GREEN


@export var _min_label: Label
@export var _max_label: Label


@warning_ignore("inferred_declaration")
var _settings := preload("res://addons/tick_debug/scripts/tick_debug_settings.gd")

var _data: TickDebug.ValueData = null
var _current_min: Variant
var _current_max: Variant
var _value_history_size: int = 150
var _history: Array[Variant] = []


## Tries to set up the graph with the given ValueData. [br]
## Return false if the value is of a type that can not be drawn with this graph,
## which currently only includes floats and ints.
func try_setup(p_value: TickDebug.ValueData) -> bool:
	if !_is_drawable_type(p_value.value):
		return false
	if p_value == null:
		push_error("[TickDebug]: SimpleGraph got handed null data.")
		return false
	
	_data = p_value
	_history.push_back(_data.value)
	_value_history_size = _settings.get_value_history_size()
	return true


func update(p_value: Variant) -> void:
	_history.push_back(p_value)
	
	if _history.size() > _value_history_size:
		_history.pop_front()
	
	queue_redraw()


func _is_drawable_type(p_value: Variant) -> bool:
	return p_value is int || p_value is float


func _draw() -> void:
	if _data == null:
		return
	
	_update_min_max_labels()
	
	var polyline: PackedVector2Array = []
	polyline.resize(_history.size())
	for i: int in _history.size():
		polyline[i] = Vector2(
				_remap_index_to_size(i),
				_remap_value_to_size(i)
		)
	
	draw_polyline(polyline, LINE_COLOR, -1.0)


# Remaps the index of a history entry to the horizontal size
# of the graph.
func _remap_index_to_size(p_i: int) -> float:
	return remap(p_i, 0, _history.size(), 0, size.x)


# Remaps the value of a history entry to the vertical size
# of the graph.
func _remap_value_to_size(p_i: int) -> float:
	return remap(
			clampf(_history[p_i], _data.min_value, _data.max_value), 
			_data.min_value, 
			_data.max_value, 
			size.y, 
			0.0
	)


func _update_min_max_labels() -> void:
	if _min_label == null || _max_label == null:
		return
	
	if _current_min != _data.min_value:
		_current_min = _data.min_value
		_min_label.text = _data.str_format(_current_min)
	if _current_min != _data.max_value:
		_current_max = _data.max_value
		_max_label.text = _data.str_format(_current_max)
