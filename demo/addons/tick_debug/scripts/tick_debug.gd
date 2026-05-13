@tool
extends Node
## Main Autoload


signal _property_untracked(id: String)


var _tracked_properties: Dictionary[String, Variant] = {}
var _new_track: bool = false


func track(p_value: Variant, p_caller: Node, p_custom_id: StringName) -> void:
	var id: String = _build_property_id(p_caller, p_custom_id)
	_tracked_properties[id] = p_value
	
	if Engine.is_editor_hint():
		# Editor-Time: directly to the dock through flag
		_new_track = true
	else:
		# Runtime: send to editor through debug bridge
		EngineDebugger.send_message("tick_debug:track", [id, p_value])


func untrack(p_caller: Node, p_custom_id: StringName) -> void:
	var id: String = _build_property_id(p_caller, p_custom_id)
	if !_tracked_properties.has(id):
		return
	_tracked_properties.erase(id)
	_property_untracked.emit(id)
	
	if !Engine.is_editor_hint():
		EngineDebugger.send_message("tick_debug:untrack", [id])


func _build_property_id(p_caller: Node, p_custom_id: StringName) -> String:
	return "%s::%s" % [p_caller.get_instance_id(), p_custom_id]
