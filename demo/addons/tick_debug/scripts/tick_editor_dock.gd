@tool
class_name TiDeEditorDock
extends TiDeDock


@export var _clear_button: Button


var _was_playing_scene: bool = false


func _ready() -> void:
	push_warning("Created! " + str(get_instance_id()))
	super._ready()
	_clear_button.pressed.connect(_on_clear_pressed)


func _process(_delta: float) -> void:
	var is_playing: bool = EditorInterface.is_playing_scene()
	
	if is_playing == _was_playing_scene:
		return
	_was_playing_scene = is_playing
	
	if is_playing:
		_on_runtime_started()
	else:
		_on_runtime_stopped()


func _on_clear_pressed() -> void:
	TickDebug._clear_tracking()
	refresh()
	print("[TickDebug]: Tracking cleared!")


# Called by the DebuggerPlugin
func _on_runtime_started() -> void:
	TickDebug._clear_tracking()
	
	_elements.clear()
	_clear_children()


# Called by the DebuggerPlugin
func _on_runtime_stopped() -> void:
	refresh()
