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
		super.update_entry(id, TickDebug._tracked_properties[id])
	_refresh_disclaimer()


# Called by the DebuggerPlugin
func update_entry_with_payload(
		p_id: String, 
		p_value_payload: Array[String]
) -> void:
	var data: TickDebug.ValueData = TickDebug.ValueData.new(p_value_payload[0])
	data.min_value = p_value_payload[1]
	data.max_value = p_value_payload[2]
	data.average = p_value_payload[3]
	
	super.update_entry(p_id, data)
	_refresh_disclaimer()
