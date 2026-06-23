@tool
class_name TiDeEditorDock
extends TiDeDock


@export var _clear_button: Button


func _ready() -> void:
	super._ready()
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
	refresh()
