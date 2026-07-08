@tool
class_name TiDeEditorDock
extends TiDeDock


@export var _clear_button: Button
@export var _custom_message_label: Label


func _ready() -> void:
	super._ready()
	_clear_button.pressed.connect(_on_clear_pressed)


func _on_clear_pressed() -> void:
	TickDebug._clear_tracking()
	refresh()
	print("[TickDebug]: Tracking cleared!")


# Called by the DebuggerPlugin
func _on_runtime_started() -> void:
	_custom_message_label.text = "Runtime started!"
	_custom_message_label.show()
	
	_elements.clear()
	_clear_children()


# Called by the DebuggerPlugin
func _on_runtime_stopped() -> void:
	_custom_message_label.text = "Runtime stopped!"
	_custom_message_label.show()
	
	refresh()
