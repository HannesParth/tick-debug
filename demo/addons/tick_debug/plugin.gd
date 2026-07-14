@tool
extends EditorPlugin


const AUTOLOAD_NAME: StringName = &"TickDebug"
const AUTOLOAD_PATH: String = "res://addons/tick_debug/scripts/tick_debug.gd"

const TOGGLE_INGAME_PANEL_ACTION: String = "toggle_tick_debug_panel"


var dock: EditorDock
var dock_scene: TiDeEditorDock
var debugger_plugin: EditorDebuggerPlugin

@warning_ignore("inferred_declaration")
var settings := preload("res://addons/tick_debug/scripts/tick_debug_settings.gd")


func _enable_plugin() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)


func _disable_plugin() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)


func _enter_tree() -> void:
	settings.setup_settings()
	ProjectSettings.settings_changed.connect(_on_project_settings_changed)
	
	if settings.get_disable_editor_dock():
		return
	
	_construct_editor_dock()
	_construct_debugger_plugin()


func _on_project_settings_changed() -> void:
	if settings.get_disable_editor_dock():
		_remove_editor_dock()
	else:
		if dock_scene || dock == null:
			_construct_editor_dock()
		if debugger_plugin != null:
			debugger_plugin.set(&"dock", dock_scene)
		else:
			_construct_debugger_plugin()


func _exit_tree() -> void:
	_remove_editor_dock()


func _construct_editor_dock() -> void:
	if dock_scene != null && dock == null:
		return
	elif dock_scene == null || dock == null:
		_remove_editor_dock()
	
	dock_scene = preload(
			"res://addons/tick_debug/scenes/tick_editor_dock.tscn"
	).instantiate()
	
	dock = EditorDock.new()
	dock.add_child(dock_scene)
	dock.title = "Tick Debug"
	
	dock.default_slot = EditorDock.DOCK_SLOT_RIGHT_UL
	dock.available_layouts = (
			EditorDock.DOCK_LAYOUT_FLOATING | EditorDock.DOCK_LAYOUT_VERTICAL
	)
	
	add_dock(dock)


func _construct_debugger_plugin() -> void:
	if debugger_plugin != null:
		_remove_debugger_plugin()
	
	debugger_plugin = preload(
			"res://addons/tick_debug/scripts/tick_debugger_plugin.gd"
	).new()
	debugger_plugin.set(&"dock", dock_scene)
	add_debugger_plugin(debugger_plugin)


func _remove_editor_dock() -> void:
	remove_dock(dock)
	dock.queue_free()
	dock = null
	dock_scene = null


func _remove_debugger_plugin() -> void:
	remove_debugger_plugin(debugger_plugin)
	debugger_plugin = null
