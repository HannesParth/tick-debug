@tool
class_name TiDeRuntimeDock
extends TiDeDock


var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	super._ready()
	gui_input.connect(_on_gui_input)


func _on_gui_input(p_event: InputEvent) -> void:
	if (
			p_event is InputEventMouseButton 
			&& (p_event as InputEventMouseButton).button_index 
			== MOUSE_BUTTON_LEFT
	):
		if (p_event as InputEventMouseButton).pressed:
			_dragging = true
			_drag_offset = get_global_mouse_position() - global_position
		else:
			_dragging = false

	elif p_event is InputEventMouseMotion and _dragging:
		global_position = get_global_mouse_position() - _drag_offset
