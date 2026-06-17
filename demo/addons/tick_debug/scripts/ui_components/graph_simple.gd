@tool
class_name TiDeGraphSimple
extends Panel


const LINE_COLOR: Color = Color.LIME_GREEN


@export var _min_label: Label
@export var _max_label: Label


@warning_ignore("inferred_declaration")
var _settings := preload("res://addons/tick_debug/scripts/tick_debug_settings.gd")

var _value: TickDebug.ValueData = null
var _current_min: Variant
var _current_max: Variant
var _value_history_size: int = 150


func try_setup(p_value: TickDebug.ValueData) -> bool:
	if !_is_drawable_type(p_value.value):
		return false
	
	_value = p_value
	_value_history_size = _settings.get_value_history_size()
	return true


func update() -> void:
	queue_redraw()


func _is_drawable_type(p_value: Variant) -> bool:
	return p_value is int || p_value is float


func _draw() -> void:
	if _value == null:
		return
	
	_update_min_max_labels()
	
	var polyline: PackedVector2Array = []
	polyline.resize(_value_history_size)
	for i: int in _value._history.size():
		polyline[i] = Vector2(
				_remap_index_to_size(i),
				_remap_value_to_size(i)
		)
	# Don't use antialiasing to speed up line drawing, but use a width that scales with
	# viewport scale to keep the line easily readable on hiDPI displays.
	draw_polyline(polyline, LINE_COLOR, -1.0)


## Remaps the index of a history entry to the horizontal size
## of the graph.
func _remap_index_to_size(p_i: int) -> float:
	return remap(p_i, 0, _value._history.size(), 0, size.x)


## Remaps the value of a history entry to the vertical size
## of the graph.
func _remap_value_to_size(p_i: int) -> float:
	return remap(
			clampf(_value._history[p_i], _value.min_value, _value.max_value), 
			_value.min_value, 
			_value.max_value, 
			size.y, 
			0.0
	)


func _update_min_max_labels() -> void:
	if _min_label == null || _max_label == null:
		return
	
	if _current_min != _value.min_value:
		_current_min = _value.min_value
		_min_label.text = TickDebug._format_value(_current_min)
	if _current_min != _value.max_value:
		_current_max = _value.max_value
		_max_label.text = TickDebug._format_value(_current_max)
