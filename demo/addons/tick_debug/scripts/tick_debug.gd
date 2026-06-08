@tool
extends Node
## Main Autoload


# TODO:
# - fix runtime dock dragging
# - fix get disable
# - add median (ostensibly min + max / 2)

signal _property_untracked(id: String)


const TOGGLE_INGAME_PANEL_ACTION: String = "toggle_tick_debug_panel"
const INGAME_PANEL_LAYER: int = 99
const INGAME_PANEL_CREATE_POS: Vector2 = Vector2(30, 30)

# Percentage safety margin of the Debugger Limits
const DEBUGGER_LIMIT_SAFETY_MARGIN: float = 0.8

# Debugger limits
# Default values are from network/limits/debugger in Project Settings
var _max_queued_messages: int = 2048
var _max_chars_per_second: int = 32768

var _queued_messages: int = 0
var _chars_this_second: int = 0
var _last_char_reset_time: float = 0.0
var _limit_error_pushed: bool = false


@warning_ignore("inferred_declaration")
var _settings := preload("res://addons/tick_debug/scripts/tick_debug_settings.gd")

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

var _tracked_properties: Dictionary[String, ValueData] = {}
var _new_track: bool = false

var _ingame_panel_layer: CanvasLayer
var _ingame_panel: TiDeRuntimeDock


func _ready() -> void:
	_max_chars_per_second = ProjectSettings.get_setting(
			"network/limits/debugger/max_chars_per_second",
			_max_chars_per_second
	)
	_max_queued_messages = ProjectSettings.get_setting(
			"network/limits/debugger/max_queued_messages",
			_max_queued_messages
	)
	
	if not InputMap.has_action(TOGGLE_INGAME_PANEL_ACTION):
		# Create default input action if no user-defined override exists.
		# We can't do it in the editor plugin's activation code as it doesn't 
		# seem to work there.
		InputMap.add_action(TOGGLE_INGAME_PANEL_ACTION)
		var event: InputEventKey = InputEventKey.new()
		event.keycode = KEY_F4
		InputMap.action_add_event(TOGGLE_INGAME_PANEL_ACTION, event)


# ====== Public API ======

# WARNING, TODO: apparently, the _process of the ingame panel is called 
# before the _process of the test scene, so it shows the actual value 
# 1 frame delayed. Does this have another fix than directly triggering a
# signal, which could easily be triggered tens of times per frame?
func track(p_value: Variant, p_caller: Node, p_custom_id: StringName) -> void:
	var id: String = _build_property_id(p_caller, p_custom_id)
	var data: ValueData
	if _tracked_properties.has(id):
		data = _tracked_properties[id]
		data.update(p_value)
	else:
		data = ValueData.new(p_value)
		_tracked_properties[id] = data
	
	# Always: set flag
	# Used by editor dock at editor time
	# Used by ingame dock at runtime
	_new_track = true
	if !Engine.is_editor_hint() && !_settings.get_disable_editor_dock():
		# Runtime: send to editor through debug bridge
		_send_tracked_message(id, data)


func untrack(p_caller: Node, p_custom_id: StringName) -> void:
	var id: String = _build_property_id(p_caller, p_custom_id)
	if !_tracked_properties.has(id):
		return
	_tracked_properties.erase(id)
	_property_untracked.emit(id)
	
	if !Engine.is_editor_hint() && !_settings.get_disable_editor_dock():
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
	elif (
			typeof(p_type_key) == TYPE_STRING 
			|| typeof(p_type_key) == TYPE_STRING_NAME
	):
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


func _send_tracked_message(p_id: String, p_data: ValueData) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0

	# Reset chars-per-second counter every second
	if now - _last_char_reset_time >= 1.0:
		_chars_this_second = 0
		_queued_messages = 0
		_last_char_reset_time = now
	
	var payload: Array[String] = p_data.payload()
	var message_chars: int = p_id.length() + get_array_string_length(payload)
	var safe_message_limit: int = int(
			_max_queued_messages * DEBUGGER_LIMIT_SAFETY_MARGIN
	)
	var safe_char_limit: int = int(
			_max_chars_per_second * DEBUGGER_LIMIT_SAFETY_MARGIN
	)

	var would_exceed_messages: bool = _queued_messages + 1 > safe_message_limit
	var would_exceed_chars: bool = (
			_chars_this_second + message_chars > safe_char_limit
	)

	if would_exceed_messages || would_exceed_chars:
		if !_limit_error_pushed:
			_limit_error_pushed = true
			var reason: String = (
					"message queue limit" if would_exceed_messages 
					else "chars/sec limit"
			)
			push_error("[TickDebug]: Debugger %s reached, " % reason
					+ "suppressing further messages this second. If you want " 
					+ "the TickDebug editor dock to be accurate, call the track "
					+ "method less than %s times per second or increase the "
					+ "network/limits/debugger/max_queued_messages "
					+ "project setting.")
		return
	
	_queued_messages += 1
	_chars_this_second += message_chars
	EngineDebugger.send_message("tick_debug:track", [p_id, payload])


func get_array_string_length(p_array: Array[String]) -> int:
	return p_array.reduce(
			func(p_acc: int, p_val: String) -> int:
				return p_acc + p_val.length()
	, 0)


func _unhandled_key_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if !event.is_action_pressed(&"toggle_tick_debug_panel"):
		return
	
	# Not yet created -> create
	if _ingame_panel == null:
		if _ingame_panel_layer != null:
			_ingame_panel_layer.queue_free()
		
		_ingame_panel_layer = CanvasLayer.new()
		var scene: PackedScene = load(
				"res://addons/tick_debug/scenes/tick_runtime_dock.tscn"
		)
		_ingame_panel = scene.instantiate()
		
		add_child(_ingame_panel_layer)
		_ingame_panel_layer.add_child(_ingame_panel)
		
		_ingame_panel_layer.layer = INGAME_PANEL_LAYER
		_ingame_panel.process_mode = Node.PROCESS_MODE_INHERIT
		_ingame_panel.global_position = INGAME_PANEL_CREATE_POS
		return
	
	# Not visible -> show and enable
	if !_ingame_panel_layer.visible:
		print("Showing ingame panel")
		_ingame_panel_layer.show()
		_ingame_panel_layer.process_mode = Node.PROCESS_MODE_PAUSABLE
		return
	
	# Visible -> hide and disable
	_ingame_panel_layer.hide()
	print("Hiding ingame panel")
	_ingame_panel_layer.process_mode = Node.PROCESS_MODE_DISABLED



class ValueData:
	var value: Variant
	var min_value: Variant
	var max_value: Variant
	var average: Variant
	
	@warning_ignore("inferred_declaration")
	var _settings := preload("res://addons/tick_debug/scripts/tick_debug_settings.gd")
	
	var _history_size: int = 150
	var _history: Array[Variant] = []
	
	var _average_disabled: bool = false
	var _graph_disabled: bool = false
	
	
	func _init(p_value: Variant) -> void:
		value = p_value
		min_value = p_value
		max_value = p_value
		average = p_value
		
		_history_size = _settings.get_value_history_size()
		_average_disabled = _settings.get_disable_average()
		_graph_disabled = _settings.get_disable_graph()
		
		if _is_valid_for_average(p_value):
			_history.append(p_value)
	
	
	func update(p_value: Variant) -> void:
		value = p_value
		
		if p_value < min_value:
			min_value = p_value
		if p_value > max_value:
			max_value = p_value
		
		# History is empty if value is non-numeric.
		# Don't use history if both average and graph are disabled.
		if _history.is_empty() || _average_disabled && _graph_disabled:
			return
		
		_history.push_back(p_value)
		
		if !_average_disabled:
			average = _get_average()
		
		if _history.size() > _history_size:
			_history.pop_front()
	
	
	func _is_valid_for_average(p_value: Variant) -> bool:
		return (
			p_value is int 
			|| p_value is float
			|| p_value is Vector2 
			|| p_value is Vector3
		)
	
	## Returns the average of the current history. [br]
	## Value has to be of a type this function can handle, which is why the
	## history is kept empty if the value is non-numeric (meaning the
	## value has to support the same usage of / and +).
	func _get_average() -> Variant:
		if _history.is_empty():
			return 0.0
	
		var sum: Variant = _get_zero_value(_history[0])
		var count: int = _history.size()
	
		for entry: Variant in _history:
			sum += entry
	
		return sum / float(count)
	
	
	func _get_zero_value(p_sample: Variant) -> Variant:
		if p_sample is Vector3:
			return Vector3.ZERO
		if p_sample is Vector2:
			return Vector2.ZERO
		return 0.0
	
	
	func payload() -> Array[String]:
		return [
			TickDebug._format_value(value),
			TickDebug._format_value(min_value),
			TickDebug._format_value(max_value),
			TickDebug._format_value(average),
		]
