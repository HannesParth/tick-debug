@tool
extends Node
## Main Autoload


# TODO:
# - put recommendation somewhere to override _equals, _add etc somewhere
#   for an object type to work
# -> I would actually have to integrate that, so average, midpoint and maybe 
#    graph actually work with that

# - when adding a new type to support, I currently need to:
# 	- add its formatting function to _type_formatters
#	- add its random value function to the test scene
#	- add whether it is numeric
#	- add its average/midpoint calculation if so
#	-> maybe I can place all this into a resource to have it centralized?
# - test performance impact of disabling editor dock
# - also see if the non-jitter labels have a performance impact
# - style?
# - test as many types as possible
# - somehow make descriptions for the project settings easily accessible
# - the message queue limit just fucking confuses me, big todo for later:
#   implement Websocket or WebRTC bridge for runtime -> editor communication

# PERFORMANCE TEST: Disabling editor dock
# DO THIS AGAIN
# V-Sync disabled


# Emitted when a property is untracked by the user.
signal _property_untracked(id: String)


## Name of the input action to toggle the runtime panel. [br]
## Couldn't get adding the input action to the project settings to stick
## (if it was added, it was only after an additional restart), so now it's added
## at runtime, and users can manually create one with the same name to 
## override it.
const TOGGLE_INGAME_PANEL_ACTION: String = "toggle_tick_debug_panel"

## Layer index the CanvasLayer of the runtime panel is set the when created. [br]
## Arbitrary high number to keep it on top.
const INGAME_PANEL_LAYER: int = 99

## Initial position the runtime panel is created at.
const INGAME_PANEL_CREATE_POS: Vector2 = Vector2(30, 30)


# Maximum number of messages per second from runtime to the editor dock using
# EngineDebugger.send_message. This is to prevent spam by Godot's 
# "Too many messages!" error.
# Set to an initial value here, overriden in _ready() by the value
# from the TickDebug project settings.
var _max_messages_per_sec: int = 8000

# Rolling window: track message timestamps to enforce a per-second budget
var _message_times: Array[float] = []
var _limit_error_pushed: bool = false


@warning_ignore("inferred_declaration")
var _settings := preload("res://addons/tick_debug/scripts/tick_debug_settings.gd")

## Custom formatting functions for non-object types, to convert a value to a 
## string. Can be extended or overridden with 
## [method TickDebug.register_formatter].
var _type_formatters: Dictionary[Variant.Type, Callable] = {
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
			return "(%.2f, %.2f)" % [p_v.x, p_v.y],
	TYPE_VECTOR2I:
		func(p_v: Variant) -> String:
			return str(p_v),
	TYPE_VECTOR3:
		func(p_v: Variant) -> String:
			return "(%.2f, %.2f, %.2f)" % [p_v.x, p_v.y, p_v.z],
	TYPE_VECTOR3I:
		func(p_v: Variant) -> String:
			return str(p_v),
	TYPE_COLOR:
		func(p_v: Variant) -> String:
			return str(p_v),
}

## Custom formatting functions for object types, to convert a value to a string.
## Can be extended or overridden with [method TickDebug.register_formatter].
var _object_formatters: Dictionary[String, Callable] = {}

# Collection of tracked properties.
# Key: The created ID for the value.
# Value: The ValueData.
var _tracked_properties: Dictionary[String, ValueData] = {}

# Flag set when a value is tracked (user calls track()).
# Reset by the debug docks.
var _new_track: bool = false

var _ingame_panel_layer: CanvasLayer
var _ingame_panel: TiDeRuntimeDock


func _ready() -> void:
	if !InputMap.has_action(TOGGLE_INGAME_PANEL_ACTION):
		# Create default input action if no user-defined override exists.
		# We can't do it in the editor plugin's activation code as it doesn't 
		# seem to work there.
		InputMap.add_action(TOGGLE_INGAME_PANEL_ACTION)
		var event: InputEventKey = InputEventKey.new()
		event.keycode = KEY_F4
		InputMap.action_add_event(TOGGLE_INGAME_PANEL_ACTION, event)
	
	if !Engine.is_editor_hint():
		_max_messages_per_sec = _settings.get_max_debugger_msg_per_sec()


# ====== Public API ======

# WARNING, TODO: apparently, the _process of the ingame panel is called 
# before the _process of the test scene, so it shows the actual value 
# 1 frame delayed. Does this have another fix than directly triggering a
# signal, which could easily be triggered tens of times per frame?

## Sets up a value to be tracked or updates an already tracked value. [br]
## [b]Note[/b] that "track" does [i]not[/i] mean that the value is automatically
## tracked after you called this once. Instead, calling this the first time
## creates a tracking reference, and every subsequent call updates it.
## [br]
## [param p_value]: The value to track. Make sure it has a registered formatter.
## For default formatters, see [member TickDebug._type_formatters]. [br]
## [param p_caller]: The Node calling this method. Just use [code]self[/code].
## used together with the next parameter to construc the internal ID. [br]
## [param p_custom_id]: Custom ID to identify this value by. Used together with
## the caller's instance ID to construct the internal tracking ID. [br]
## Also used as the display name of the value. [br]
## [br]
## [b]Returns[/b] the constructed tracking ID for the value.
func track(p_value: Variant, p_caller: Node, p_custom_id: StringName) -> String:
	var id: String = _build_tracking_id(p_caller, p_custom_id)
	var data: ValueData = _track_value(p_value, id)
	
	if !Engine.is_editor_hint() && !_settings.get_disable_editor_dock():
		# Runtime: send to editor through debug bridge
		_send_tracked_message(id, data)
	
	return id


## Removes a value from tracking. Needs the same [param p_caller] Node reference
## and [param p_custom_id] used for tracking the value. [br]
## [br]
## To remove the tracking with the constructed tracking ID returned by
## [method TickDebug.track], use [method TickDebug.untrack_by_constructed_id].
func untrack(p_caller: Node, p_custom_id: StringName) -> void:
	var id: String = _build_tracking_id(p_caller, p_custom_id)
	untrack_by_constructed_id(id)


## Removes a value from tracking. Needs the constructed tracking ID returned by 
## [method TickDebug.track]. [br]
## [br]
## To remove the tracking with the same parameters as with 
## [method TickDebug.track], use [method TickDebug.untrack].
func untrack_by_constructed_id(p_constructed_id: String) -> void:
	if !_tracked_properties.has(p_constructed_id):
		return
	_tracked_properties.erase(p_constructed_id)
	_property_untracked.emit(p_constructed_id)
	
	if !Engine.is_editor_hint() && !_settings.get_disable_editor_dock():
		EngineDebugger.send_message("tick_debug:untrack", [p_constructed_id])


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

# Used by the DebuggerPlugin to track a value where the already constructed ID
# has been sent by the runtime TickDebug instance.
func _track_editor(p_value: Variant, p_id: StringName) -> void:
	_track_value(p_value, p_id)


# Internal method to track a value.
# [method TickDebug.track] just constructs the tracking ID and calls this.
# Also used by the DebuggerPlugin to track a value with its constructed ID 
# directly, which it got from the runtime instance.
func _track_value(p_value: Variant, p_id: StringName) -> ValueData:
	var data: ValueData
	if _tracked_properties.has(p_id):
		data = _tracked_properties[p_id]
		data.update(p_value)
	else:
		data = ValueData.new(p_value)
		_tracked_properties[p_id] = data
		
		# Notify user if value type has no formatter
		if !_has_formatter(p_value):
			var msg: String = "[TickDebug]: The given value [" + str(p_value)\
					+ "has no registered formatter. See TickDebug.register_formatter"
			printerr(msg)
			push_error(msg)
	
	# Always: set flag
	# Used by editor dock at editor time
	# Used by ingame dock at runtime
	_new_track = true
	return data


# Clears tracking.
# Called by the DebuggerPlugin and editor dock.
func _clear_tracking() -> void:
	_tracked_properties.clear()
	_new_track = false


# Constructs the tracking id for a value from the instance id of the caller
# and the given custom id.
func _build_tracking_id(p_caller: Node, p_custom_id: StringName) -> String:
	return "%s::%s" % [p_caller.get_instance_id(), p_custom_id]


# Formats a value to a string using a formatter from _type_formatters or
# _object_formatters.
# If they have no formatter, just uses str().
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


# Checks whether the type of the given value has a registered formatter.
# For objects, checks with the values script global name and class name.
func _has_formatter(p_value: Variant) -> bool:
	var type: int = typeof(p_value)
	if type == TYPE_NIL:
		return false
	elif type == TYPE_OBJECT:
		var obj: Object = p_value as Object
		var script: Script = obj.get_script() as Script
		if script != null && _object_formatters.has(script.get_global_name()):
			return true
		return _object_formatters.has(obj.get_class())
	else:
		return _type_formatters.has(type)


# Sends a message from runtime to editor using EngineDebugger.send_message().
# Tracks the amount of messages per second using a rolling window of timestamps,
# and pushes an error if _max_messages_per_sec is exceeded.
# This is to prevent triggering Godot's own "Too many messages!" error.
func _send_tracked_message(p_id: String, p_data: ValueData) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	
	# Evict timestamps older than 1 second
	while !_message_times.is_empty() && _message_times[0] < now - 1.0:
		_message_times.pop_front()
	
	if _message_times.size() >= _max_messages_per_sec:
		if !_limit_error_pushed:
			_limit_error_pushed = true
			var elapsed: float = _message_times[-1] - _message_times[0]
			var estimated_rate: int = roundi(_message_times.size() / elapsed)
			push_error(
				"[TickDebug]: Approaching debugger queue limit, suppressing "
				+ "further messages. Call track() less than %d " % _max_messages_per_sec
				+ "times per second (current: %d)," % estimated_rate
				+ "or increase debug/tick_debug/max_debugger_messages_per_second "
				+ "in Project Settings."
			)
		return
	
	var value: Variant
	if p_data.value is Object:
		value = _format_value(p_data.value)
	else:
		value = p_data.value
	
	_message_times.append(now)
	EngineDebugger.send_message("tick_debug:track", [p_id, value])


# Toggles the TickDebug ingame panel using the associated input action.
# If the panel has not been created yet, instantiates it.
# If it has been created, shows and hides the same instance.
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
		_ingame_panel_layer.show()
		_ingame_panel_layer.process_mode = Node.PROCESS_MODE_PAUSABLE
		return
	
	# Visible -> hide and disable
	_ingame_panel_layer.hide()
	_ingame_panel_layer.process_mode = Node.PROCESS_MODE_DISABLED


## Data class for tracking a value.
## Calculates all snapshots and keeps the history used for calculating the 
## average value and for the graph.
class ValueData:
	var value: Variant
	var min_value: Variant
	var max_value: Variant
	var midpoint_value: Variant
	var average: Variant
	
	@warning_ignore("inferred_declaration")
	var _settings := preload("res://addons/tick_debug/scripts/tick_debug_settings.gd")
	
	var _history_size: int = 150
	var _history: Array[Variant] = []
	
	var _average_disabled: bool = false
	var _midpoint_disabled: bool = false
	var _graph_disabled: bool = false
	
	var is_numeric: bool = true
	
	
	func _init(p_value: Variant) -> void:
		value = p_value
		is_numeric = _is_numeric_type(p_value)
		
		_history_size = _settings.get_value_history_size()
		_average_disabled = _settings.get_disable_average()
		_midpoint_disabled = _settings.get_disable_midpoint()
		_graph_disabled = _settings.get_disable_graph()
		
		if is_numeric:
			min_value = p_value
			max_value = p_value
			midpoint_value = p_value
			average = p_value
			
			_history.append(p_value)
	
	
	func update(p_value: Variant) -> void:
		value = p_value
		
		if is_numeric:
			_update_numeric(p_value)


	func _update_numeric(p_value: Variant) -> void:
		var minmax_changed: bool = false
		
		if p_value < min_value:
			min_value = p_value
			minmax_changed = true
		if p_value > max_value:
			max_value = p_value
			minmax_changed = true
		
		if minmax_changed && !_midpoint_disabled:
			midpoint_value = (min_value + max_value) / 2
		
		# History is empty if value is non-numeric.
		# Don't use history if both average and graph are disabled.
		if _history.is_empty() || _average_disabled && _graph_disabled:
			return
		
		_history.push_back(p_value)
		
		if !_average_disabled:
			average = _get_average()
		
		if _history.size() > _history_size:
			_history.pop_front()
	
	
	# Whether the value is of a type where the numeric snapshots and 
	# calculations make sense (as opposed to String or Color)
	func _is_numeric_type(p_value: Variant) -> bool:
		return (
			p_value is int 
			|| p_value is float
			|| p_value is Vector2
			|| p_value is Vector2i
			|| p_value is Vector3
			|| p_value is Vector3i
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
		if p_sample is Vector3i:
			return Vector3i.ZERO
		if p_sample is Vector2:
			return Vector2.ZERO
		if p_sample is Vector2i:
			return Vector2i.ZERO
		return 0.0
	
