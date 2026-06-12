@tool
class_name TiDeEditorDock
extends TiDeDock


@export var _clear_button: Button


func _ready() -> void:
	_clear_button.pressed.connect(
			func() -> void:
				TickDebug._clear_tracking()
				refresh()
				print("[TickDebug]: Tracking cleared!")
	)

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


# Editor TickDebug instance is updated by the DebuggerPlugin
func _process(_p_delta: float) -> void:
	if !Engine.is_editor_hint():
		return
	
	_refresh_disclaimer()
	if !TickDebug._new_track:
		return
	
	for id: String in TickDebug._tracked_properties:
		update_entry(id, TickDebug._tracked_properties[id])
	
	TickDebug._new_track = false
