@tool
class_name TiDiDebuggerPlugin
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
		dock.on_untracked(data[0])
		return true
	return false


# Called when runtime starts
func _setup_session(p_session_id: int) -> void:
	var session: EditorDebuggerSession = get_session(p_session_id)
	
	session.started.connect(TickDebug._clear_tracking)
	session.started.connect(dock._on_runtime_started)
	
	session.stopped.connect(dock._on_runtime_stopped)
