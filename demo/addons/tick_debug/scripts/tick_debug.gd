@tool
extends Node
## Main Autoload


signal _property_untracked(id: String)


const INGAME_PANEL_LAYER: int = 99
const INGAME_PANEL_CREATE_POS: Vector2 = Vector2(30, 30)


var _type_formatters: Dictionary = {
	TYPE_BOOL:
		func(p_v: Variant) -> String:
			return "true" if p_v else "false",
	TYPE_INT:
		func(p_v: Variant) -> String:
			return str(p_v),
	TYPE_FLOAT:
		func(p_v: Variant) -> String:
			return "%.2f" % p_v,
	TYPE_STRING:
		func(p_v: Variant) -> String:
			return p_v,
	TYPE_VECTOR2:
		func(p_v: Variant) -> String:
			return str(p_v),
	TYPE_VECTOR3:
		func(p_v: Variant) -> String:
			return str(p_v),
	TYPE_COLOR:
		func(p_v: Variant) -> String:
			return str(p_v),
}

var _object_formatters: Dictionary[String, Callable] = {}

var _tracked_properties: Dictionary[String, String] = {}
var _new_track: bool = false

var _ingame_panel_layer: CanvasLayer
var _ingame_panel: TiDiIngameDock


# ====== Public API ======

# WARNING, TODO: apparently, the _process of the ingame panel is called 
# before the _process of the test scene, so it shows the actual value 
# 1 frame delayed. Does this have another fix than directly triggering a
# signal, which could easily be triggered tens of times per frame?
func track(p_value: Variant, p_caller: Node, p_custom_id: StringName) -> void:
	var id: String = _build_property_id(p_caller, p_custom_id)
	var formatted: String = _format_value(p_value)
	_tracked_properties[id] = formatted
	
	# Always: set flag
	# Used by editor dock at editor time
	# Used by ingame dock at runtime
	_new_track = true
	if !Engine.is_editor_hint():
		# Runtime: send to editor through debug bridge
		EngineDebugger.send_message("tick_debug:track", [id, formatted])


func untrack(p_caller: Node, p_custom_id: StringName) -> void:
	var id: String = _build_property_id(p_caller, p_custom_id)
	if !_tracked_properties.has(id):
		return
	_tracked_properties.erase(id)
	_property_untracked.emit(id)
	
	if !Engine.is_editor_hint():
		EngineDebugger.send_message("tick_debug:untrack", [id])


## Registers a formatter to convert the given type to a string. Can be used
## to override existing formatters. [br]
## [param p_type_key]: Either a built-in [Variant.Type] from 
## [annotation @GlobalScope], or a class name as a String. [br]
## [param p_callable]: The formatting [Callable]. Has to take the value as a 
## parameter and return a String. [br]
## Examples: [br]
## [codeblock]
## TickDebug.register_formatter("MyEnemyData", func(p_v: Variant) -> String:
## 	return "Enemy[%s hp=%d]" % [p_v.name, p_v.health]
## )
##
## TickDebug.register_formatter(TYPE_FLOAT, func(p_v: Variant) -> String:
## 	return "%.2f" % p_v
## )
## [/codeblock]
func register_formatter(p_type_key: Variant, p_callable: Callable) -> void:
	if typeof(p_type_key) == TYPE_INT:
		_type_formatters[p_type_key] = p_callable
	elif typeof(p_type_key) == TYPE_STRING or typeof(p_type_key) == TYPE_STRING_NAME:
		_object_formatters[str(p_type_key)] = p_callable


# ====== Private Methods ======

func _build_property_id(p_caller: Node, p_custom_id: StringName) -> String:
	return "%s::%s" % [p_caller.get_instance_id(), p_custom_id]


func _format_value(p_value: Variant) -> String:
	var builtin_type: int = typeof(p_value)
	
	# Objects: traverse script/class hierarchy
	if builtin_type == TYPE_OBJECT && p_value != null:
		var obj: Object = p_value as Object
		var script: Script = obj.get_script()
		
		# Check scripts first, with inheritance
		while script != null:
			var script_name: String = script.get_global_name()
			if script_name != "" and _object_formatters.has(script_name):
				return _object_formatters[script_name].call(p_value)
			script = script.get_base_script()
		
		# Check native class with inheritance
		var class_name_str: String = obj.get_class()
		while class_name_str != "":
			if _object_formatters.has(class_name_str):
				return _object_formatters[class_name_str].call(p_value)
			class_name_str = ClassDB.get_parent_class(class_name_str)
		
		# Fallback for objects
		return "<No Object Formatter: %s>" % obj.get_class()
	
	# Primitive: direct lookup
	if _type_formatters.has(builtin_type):
		return (_type_formatters[builtin_type] as Callable).call(p_value)
	
	# Last fallback, just let built-in string conversion handle it
	return str(p_value)


func _unhandled_key_input(event: InputEvent) -> void:
	if !event.is_action_pressed(&"toggle_tick_debug_panel"):
		return
	
	# Not yet created -> create
	if _ingame_panel == null:
		if _ingame_panel_layer != null:
			_ingame_panel_layer.queue_free()
		
		_ingame_panel_layer = CanvasLayer.new()
		_ingame_panel = TiDiIngameDock.new()
		
		add_child(_ingame_panel_layer)
		_ingame_panel_layer.add_child(_ingame_panel)
		
		_ingame_panel_layer.layer = INGAME_PANEL_LAYER
		_ingame_panel.process_mode = Node.PROCESS_MODE_INHERIT
		_ingame_panel.global_position = INGAME_PANEL_CREATE_POS
		return
	
	# Not visible -> show and enable
	if !_ingame_panel_layer.visible:
		_ingame_panel_layer.show()
		_ingame_panel_layer.process_mode = Node.PROCESS_MODE_PAUSABLE
		return
	
	# Visible -> hide and disable
	_ingame_panel_layer.hide()
	_ingame_panel_layer.process_mode = Node.PROCESS_MODE_DISABLED
	
