@tool
extends EditorPlugin


const DOCK_PATH: String = "res://addons/tick_debug/scenes/tick_debug_dock.tscn"
const DEBUGGER_PLUGIN_PATH: String = "res://addons/tick_debug/scripts/tick_debugger_plugin.gd"

const AUTOLOAD_NAME: StringName = &"TickDebug"
const AUTOLOAD_PATH: String = "res://addons/tick_debug/scripts/tick_debug.gd"

const TOGGLE_INGAME_PANEL_ACTION: String = "toggle_tick_debug_panel"


var dock: EditorDock
var dock_scene: TiDiEditorDock
var debugger_plugin: TiDiDebuggerPlugin


func _enable_plugin() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)
	_register_input_actions()


func _disable_plugin() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)
	_unregister_input_actions()


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


func _register_input_actions() -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = KEY_F4
	event.ctrl_pressed = false
	
	if !ProjectSettings.has_setting("input/" + TOGGLE_INGAME_PANEL_ACTION):
		var action_settings: Dictionary = {
			"deadzone": 0.5,
			"events": [event]
		}
		ProjectSettings.set_setting(
				"input/" + TOGGLE_INGAME_PANEL_ACTION, 
				action_settings
		)
		# This tells Godot to treat it as an InputEvent action 
		# (shows in Project Settings UI)
		ProjectSettings.set_initial_value(
				"input/" + TOGGLE_INGAME_PANEL_ACTION, 
				action_settings
		)
		ProjectSettings.save()
	
	# Always sync runtime InputMap from ProjectSettings
	InputMap.load_from_project_settings()


func _unregister_input_actions() -> void:
	if ProjectSettings.has_setting("input/" + TOGGLE_INGAME_PANEL_ACTION):
		ProjectSettings.set_setting("input/" + TOGGLE_INGAME_PANEL_ACTION, null)
		ProjectSettings.save()

	# Reload so the removed action is gone from runtime InputMap too
	InputMap.load_from_project_settings()
