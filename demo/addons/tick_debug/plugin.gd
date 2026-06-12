@tool
extends EditorPlugin


const DOCK_PATH: String = "res://addons/tick_debug/scenes/tick_editor_dock.tscn"
const DEBUGGER_PLUGIN_PATH: String = "res://addons/tick_debug/scripts/tick_debugger_plugin.gd"

const AUTOLOAD_NAME: StringName = &"TickDebug"
const AUTOLOAD_PATH: String = "res://addons/tick_debug/scripts/tick_debug.gd"

const TOGGLE_INGAME_PANEL_ACTION: String = "toggle_tick_debug_panel"


var dock: EditorDock
var dock_scene: TiDeEditorDock
var debugger_plugin: TiDiDebuggerPlugin

@warning_ignore("inferred_declaration")
var settings := preload("res://addons/tick_debug/scripts/tick_debug_settings.gd")


func _enable_plugin() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)
	
	# FIXME: this appears to do nothing
	#_register_input_actions()


func _disable_plugin() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)
	# Don't remove the project setting's value and input map action,
	# as the plugin may be re-enabled in the future.


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
			debugger_plugin.dock = dock_scene
		else:
			_construct_debugger_plugin()


func _exit_tree() -> void:
	_remove_editor_dock()


func _construct_editor_dock() -> void:
	if dock_scene != null:
		_remove_editor_dock()
	
	dock_scene = preload(DOCK_PATH).instantiate()
	
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
	
	debugger_plugin = preload(DEBUGGER_PLUGIN_PATH).new()
	debugger_plugin.dock = dock_scene
	add_debugger_plugin(debugger_plugin)


func _remove_editor_dock() -> void:
	remove_dock(dock)
	dock.queue_free()
	dock = null
	dock_scene = null


func _remove_debugger_plugin() -> void:
	remove_debugger_plugin(debugger_plugin)
	debugger_plugin = null


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
		ProjectSettings.save()
	
	# Always sync runtime InputMap from ProjectSettings
	InputMap.load_from_project_settings()


func _unregister_input_actions() -> void:
	if ProjectSettings.has_setting("input/" + TOGGLE_INGAME_PANEL_ACTION):
		ProjectSettings.set_setting("input/" + TOGGLE_INGAME_PANEL_ACTION, null)
		ProjectSettings.save()

	# Reload so the removed action is gone from runtime InputMap too
	InputMap.load_from_project_settings()
