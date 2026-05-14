@tool
class_name TiDiIngameDock
extends Panel


## Pixel size of a single margin of the whole panel.
## Means this value is applied once at each side.
const MARGIN_PX: int = 10

## Pixel size of the horizontal space left between the header and value of a
## property.
const PROPERTY_X_SPACE: int = 12

## Pixel size of the vertical space left between individual property elements.
const PROPERTY_Y_SPACE: int = 10

## Pixel size of the padding applied once each left and right of the value
## of a property element.
const VALUE_X_PADDING: int = 8

## Pixel size of the padding applied once each top and bottom of the value
## of a property element.
const VALUE_Y_PADDING: int = 4

const FONT_SIZE: int = 16
const FONT_COLOR: Color = Color.WHITE


var default_font: Font = ThemeDB.fallback_font

var _elements: Dictionary[String, Element] = {}

var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	gui_input.connect(_on_gui_input)


func _process(_p_delta: float) -> void:
	_update_property_entries()


#region Updating Property Entries
func _update_property_entries() -> void:
	if Engine.is_editor_hint():
		return
	
	if !TickDebug._new_track:
		return
	
	for id: String in TickDebug._tracked_properties:
		_update_entry(id, TickDebug._tracked_properties[id])
	
	TickDebug._new_track = false


func _update_entry(p_id: String, p_value: String) -> void:
	if _elements.has(p_id):
		_elements[p_id].update(p_value)
	else:
		var ele: Element = Element.new(p_id.split("::")[1], p_value)
		_elements[p_id] = ele
	
	queue_redraw()
#endregion


#region Drawing
func _draw() -> void:
	if Engine.is_editor_hint():
		return
	
	var last_pos: Vector2 = Vector2(MARGIN_PX, MARGIN_PX + VALUE_Y_PADDING)
	
	# Calc element sizes
	var max_sizes: LargestEleSizes = _calc_element_sizes()
	var total_needed_width: float = max_sizes.ele_width + MARGIN_PX * 2
	
	# Resize panel
	if size.x != total_needed_width:
		size.x = total_needed_width
	if size.y != max_sizes.ele_height:
		size.y = max_sizes.ele_height
	
	# Draw property elements
	for ele: Element in _elements.values():
		_draw_property_element(ele, last_pos, max_sizes)
		last_pos = Vector2(
				MARGIN_PX, 
				last_pos.y + ele.full_size.y + PROPERTY_Y_SPACE
		)


func _draw_property_element(
		p_element: Element, 
		p_origin: Vector2,
		p_max_sizes: LargestEleSizes
) -> void:
	var value_origin: Vector2 = Vector2(
			p_origin.x + p_max_sizes.header_width + PROPERTY_X_SPACE,
			p_origin.y
	)
	
	var padding_vec: Vector2 = Vector2(VALUE_X_PADDING, VALUE_Y_PADDING)
	draw_rect(
			Rect2(
				value_origin - padding_vec, 
				Vector2(p_max_sizes.value_width, p_element.full_size.y)), 
			Color(0.113, 0.113, 0.113, 1.0)
	)
	
	_draw_text(p_element.header, p_origin, p_element.header_size)
	_draw_text(
			p_element.value, 
			value_origin, 
			p_element.value_size - padding_vec * 2
	)


func _draw_text(p_text: String, p_pos: Vector2, p_size: Vector2) -> void:
	draw_string(
			default_font, 
			Vector2(p_pos.x, p_pos.y + p_size.y - FONT_SIZE * 0.3), 
			p_text,
			HORIZONTAL_ALIGNMENT_LEFT, 
			-1, 
			FONT_SIZE, 
			FONT_COLOR
	)
#endregion


#region Calculating Sizes
func _calc_element_sizes() -> LargestEleSizes:
	var max_sizes: LargestEleSizes = LargestEleSizes.new()
	
	for ele: Element in _elements.values():
		ele.header_size = _get_text_size(ele.header)
		max_sizes.check_largest_header_width(ele.header_size.x)
		
		ele.value_size = _get_text_size(ele.value)
		max_sizes.check_widest_value_no_padding(ele.value_size.x)
		ele.value_size = ele.value_size + Vector2(
				VALUE_X_PADDING, 
				VALUE_Y_PADDING
		) * 2
		max_sizes.check_largest_value_width(ele.value_size.x)
		
		ele.full_size = Vector2(
			max_sizes.header_width + PROPERTY_X_SPACE + ele.value_size.x,
			maxf(ele.header_size.y, ele.value_size.y)
		)
		max_sizes.check_largest_ele_width(ele.full_size.x)
		
		max_sizes.ele_height += ele.full_size.y
	
	# Add spacing between properties and margin to sum
	max_sizes.ele_height += (
			(_elements.size() - 1) * PROPERTY_Y_SPACE 
			+ MARGIN_PX * 2
	)
	
	return max_sizes


func _get_text_size(p_text: String) -> Vector2:
	return default_font.get_string_size(
			p_text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE
	)
#endregion


#region Drag Input Handling
func _on_gui_input(p_event: InputEvent) -> void:
	if (
			p_event is InputEventMouseButton 
			&& (p_event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
	):
		if (p_event as InputEventMouseButton).pressed:
			_dragging = true
			_drag_offset = get_global_mouse_position() - global_position
		else:
			_dragging = false
	
	elif p_event is InputEventMouseMotion && _dragging:
		global_position = get_global_mouse_position() - _drag_offset
#endregion


class Element:
	var header_size: Vector2
	
	## Pixel size of the value text with padding
	var value_size: Vector2
	var full_size: Vector2
	var header: String
	var value: String
	
	
	func _init(p_header: String, p_value: String) -> void:
		header = p_header
		value = p_value
	
	
	func update(p_value: String) -> void:
		value = p_value


class LargestEleSizes:
	var header_width: float = 0.0
	
	var value_width: float = 0.0
	var value_no_padding: float = 0.0
	
	var ele_width: float = 0.0
	var ele_height: float = 0.0
	
	
	func check_largest_header_width(against: float) -> void:
		if against > header_width:
			header_width = against
	
	
	func check_largest_value_width(against: float) -> void:
		if against > value_width:
			value_width = against
	
	
	func check_widest_value_no_padding(against: float) -> void:
		if against > value_no_padding:
			value_no_padding = against
	
	
	func check_largest_ele_width(against: float) -> void:
		if against > ele_width:
			ele_width = against
	
	
