@tool
class_name TiDeEditorDock
extends TiDeDock


# Called by the DebuggerPlugin
func _on_runtime_started() -> void:
	_elements.clear()
	_clear_children()


# Called by the DebuggerPlugin
func _on_runtime_stopped() -> void:
	_sync_from_editor_autoload()


func _sync_from_editor_autoload() -> void:
	_elements.clear()
	_clear_children()
	
	for id: String in TickDebug._tracked_properties:
		update_entry(id, TickDebug._tracked_properties[id])
	_refresh_disclaimer()


# Called by the DebuggerPlugin
func update_entry(p_id: String, p_value: String) -> void:
	super.update_entry(p_id, p_value)
	_refresh_disclaimer()
