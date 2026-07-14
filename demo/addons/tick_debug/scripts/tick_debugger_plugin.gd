@tool
extends EditorDebuggerPlugin


var dock: TiDeEditorDock


func _has_capture(prefix: String) -> bool:
	return prefix == "tick_debug"


func _capture(message: String, data: Array, _session_id: int) -> bool:
	if message == "tick_debug:track":
		# data[0] = id, data[1] = value
		TickDebug._track_editor(data[1], data[0])
		return true
	elif message == "tick_debug:untrack":
		# data[0] = full constructed tracking ID
		TickDebug.untrack_by_constructed_id(data[0])
		return true
	return false
