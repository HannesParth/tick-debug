@tool
extends EditorPlugin


const DOCK_PATH: String = "res://addons/tick_debug/scenes/tick_debug_dock.tscn"
const DEBUGGER_PLUGIN_PATH: String = "res://addons/tick_debug/scripts/tick_debugger_plugin.gd"

const AUTOLOAD_NAME: StringName = &"TickDebug"
const AUTOLOAD_PATH: String = "res://addons/tick_debug/scripts/tick_debug.gd"

var dock: EditorDock
var dock_scene: TiDiEditorDock
var debugger_plugin: TiDiDebuggerPlugin


func _enable_plugin() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)


func _disable_plugin() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)


func _enter_tree() -> void:
	dock_scene = preload(DOCK_PATH).instantiate()
	
	dock = EditorDock.new()
	dock.add_child(dock_scene)
	dock.title = "Tick Debug"
	
	dock.default_slot = EditorDock.DOCK_SLOT_RIGHT_UR
	dock.available_layouts = EditorDock.DOCK_LAYOUT_FLOATING | EditorDock.DOCK_LAYOUT_VERTICAL
	
	add_dock(dock)
	
	debugger_plugin = preload(DEBUGGER_PLUGIN_PATH).new()
	debugger_plugin.dock = dock_scene
	add_debugger_plugin(debugger_plugin)


func _exit_tree() -> void:
	remove_debugger_plugin(debugger_plugin)
	debugger_plugin = null
	
	remove_dock(dock)
	dock.queue_free()
	dock = null
	dock_scene = null
