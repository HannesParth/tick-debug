@tool
extends Node
## Main Autoload of the TickDebug addon for debugging continuously changing
## values.
##
## The central functions are [method TickDebug.track] and 
## [method TickDebug.untrack]. [br]
## If you want to track a type that is not covered in
## [code]res://addons/tick_debug/scripts/track_types[/code], see
## [method TickDebug.register_track_type].


# TODO:
# - get some good screenshots -> in process, test in NPNG
# - write GitHub README
#   - don't forget to explain how the debug bridge works, message queue and stuff
#   - explain about class name usage in TickDebug
#   - give heads up that upon first adding the folder, there are probably a bunch
#     of parse errors, because the Autoload doesn't exist till plugin activation
#   - explain that there is no enum Variant.Type, and that passing one to track 
#     will either use the direct int key, or use Enum.keys()[variable]
#   - How to install section!
# - create GitHub Release -> 1.0.0
# - upload to asset lib and store
# - advertize on reddit and godot discord
#
# Todo for 1.1:
# - complex line graph inspired by https://store.godotengine.org/asset/jeditor/debug-graph/
# - color history "graph"
# - add an option for rolling window average


## Emitted at the end of a frame, when a tracking value was added or updated 
## that frame.
signal _tracking_changed_this_frame()

## Emitted when a property is untracked by the user.
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


## Maximum number of messages per second from runtime to the editor dock using
## [method EngineDebugger.send_message]. This is to prevent spam by Godot's 
## "Too many messages!" error. [br]
## Set to an initial value here, overriden in _ready() by the value
## from the TickDebug project settings.
var _max_messages_per_sec: int = 8000

# Rolling window: track message timestamps to enforce a per-second budget
var _message_times: Array[float] = []
var _limit_error_pushed: bool = false


@warning_ignore("inferred_declaration")
var _settings := preload("res://addons/tick_debug/scripts/tick_debug_settings.gd")

## Collection of [TiDeTrackType]s, with their type as key. [br]
## TickDebug uses implementations of this class for proper string formatting
## and calculations. [br]
## Register new implementations or override existing ones using
## [method TickDebug.register_track_type]. Look at 
## [code]res://addons/tick_debug/scripts/track_types[/code] for existing
## implementations to use as examples.
var _track_types: Dictionary[Variant, TiDeTrackType] = {}

# Collection of tracked properties.
# Key: The created ID for the value.
# Value: The ValueData.
var _tracked_properties: Dictionary[String, ValueData] = {}

# Flag set when a value is tracked (user calls track()) this frame.
# Reset at the end of the frame, emitting _tracking_changed_this_frame.
var _new_track: bool = false

var _ingame_panel_layer: CanvasLayer
var _ingame_panel: TiDeDock


# ====== Setup ======

func _init() -> void:
	_register_default_track_types()


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


func _register_default_track_types() -> void:
	register_track_type(preload(
			"res://addons/tick_debug/scripts/track_types/track_type_bool.gd"
	).new())
	register_track_type(preload(
			"res://addons/tick_debug/scripts/track_types/track_type_color.gd"
	).new())
	register_track_type(preload(
			"res://addons/tick_debug/scripts/track_types/track_type_float.gd"
	).new())
	register_track_type(preload(
			"res://addons/tick_debug/scripts/track_types/track_type_int.gd"
	).new())
	register_track_type(preload(
			"res://addons/tick_debug/scripts/track_types/track_type_string.gd"
	).new())
	register_track_type(preload(
			"res://addons/tick_debug/scripts/track_types/track_type_vector2.gd"
	).new())
	register_track_type(preload(
			"res://addons/tick_debug/scripts/track_types/track_type_vector2i.gd"
	).new())
	register_track_type(preload(
			"res://addons/tick_debug/scripts/track_types/track_type_vector3.gd"
	).new())
	register_track_type(preload(
			"res://addons/tick_debug/scripts/track_types/track_type_vector3i.gd"
	).new())


func _process(_delta: float) -> void:
	_check_for_new_track.call_deferred()


# Check at the end of every frame if track() was called.
# If so, emit the signal and reset _new_track.
func _check_for_new_track() -> void:
	if _new_track:
		_tracking_changed_this_frame.emit()
		_new_track = false

# ====== Public API ======

## Sets up a value to be tracked or updates an already tracked value. [br]
## [b]Note[/b] that "track" does [i]not[/i] mean that the value is automatically
## tracked after you called this once. Instead, calling this the first time
## creates a tracking reference, and every subsequent call updates it. [br]
## [br]
## [param p_value]: The value to track. Make sure it has a registered TrackType.
## For default formatters, see 
## [code]res://addons/tick_debug/scripts/track_types[/code]. [br]
## [br]
## [param p_caller]: The Node calling this method. Used together with the next 
## parameter to construc the internal ID. Recommended: [code]self[/code]. [br]
## [param p_custom_id]: Custom ID to identify this value by. Used together with
## the caller's instance ID to construct the internal tracking ID. [br]
## Also used as the display name of the value. [br]
## [br]
## [b]Returns[/b] the constructed tracking ID of the value.
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
## [br]
## [b]Note:[/b] Calling this is not necessary for cleanup when ending playmode.
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


## Registers a [TiDeTrackType] or overrides an existing one. [br]
## TrackTypes are used as central containers for string formatting, calculations,
## and logic checks. [br]
## See [code]res://addons/tick_debug/scripts/track_types[/code] for default 
## implementations.
func register_track_type(p_track_type: TiDeTrackType) -> void:
	_track_types[p_track_type.get_type()] = p_track_type


# ====== Private Methods ======

# Used by the DebuggerPlugin to track a value where the already constructed ID
# has been sent by the runtime TickDebug instance.
func _track_editor(p_value: Variant, p_id: StringName) -> void:
	_track_value(p_value, p_id)


# Internal method to track a value.
# [method TickDebug.track] just constructs the tracking ID and calls this.
func _track_value(p_value: Variant, p_id: StringName) -> ValueData:
	var data: ValueData
	if _tracked_properties.has(p_id):
		data = _tracked_properties[p_id]
		data.update(p_value)
	else:
		data = ValueData.new(p_value)
		_tracked_properties[p_id] = data
		
		# Notify user if value type has no formatter
		if !_has_track_type(p_value):
			var msg: String = "[TickDebug]: The given value [%s] " % p_value\
					+ "has no registered Track Type. See TickDebug.register_track_type."
			printerr(msg)
			push_error(msg)
	
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


# Formats a value to a string using the format() method of a registered 
# TiDeTrackType.
# If none is registered, just uses str().
# Only used as a fallback in cases where the TrackType instance of a ValueData 
# is not directly accessible.
func _format_value(p_value: Variant) -> String:
	var track_type: TiDeTrackType = _find_track_type(p_value)
	if track_type != null:
		return track_type.format(p_value)
	
	return str(p_value)


# Finds the TiDeTrackType of a value type.
# For non-objects, uses the Variant.Type.
# For objects, checks using class name and script name, traversing the 
# inheritance recusively.
# Returns null if the type could not be found in _track_types.
func _find_track_type(p_value: Variant) -> TiDeTrackType:
	if p_value == null:
		return null
	
	var builtin_type: int = typeof(p_value)
	if builtin_type == TYPE_NIL:
		return null
	
	if builtin_type == TYPE_OBJECT:
		var obj: Object = p_value as Object
		var script: Script = obj.get_script()
		
		# Check scripts first, with inheritance
		while script != null:
			var script_name: String = script.get_global_name()
			if script_name != "" && _track_types.has(script_name):
				return _track_types[(script_name as Variant)]
			script = script.get_base_script()
		
		# Check native class with inheritance
		var class_name_str: String = obj.get_class()
		while class_name_str != "":
			if _track_types.has(class_name_str):
				return _track_types[(class_name_str as Variant)]
			class_name_str = ClassDB.get_parent_class(class_name_str)
		
	# Primitive: direct lookup
	if _track_types.has(builtin_type):
		return _track_types[(builtin_type as Variant)]
	
	# No TrackType
	return null


# Checks whether the type of the given value has a registered TiDeTrackType.
# For objects, checks with the values script global name and class name.
func _has_track_type(p_value: Variant) -> bool:
	return _find_track_type(p_value) != null


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
		value = p_data.str_format(p_data.value)
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
## Holds the value's TrackType, which is used for logic checks, some calculations
## and string formatting.
## Keeps a value history, used for calculating the average and by the simple
## graph. To set the history size, see 
## [code]debug/tick_debug/value_history_size[/code] in the project settings.
class ValueData:
	var value: Variant
	var min_value: Variant
	var max_value: Variant
	var midpoint_value: Variant
	
	var average: Variant
	var total_sum: Variant
	var total_count: int
	
	@warning_ignore("inferred_declaration")
	var _settings := preload("res://addons/tick_debug/scripts/tick_debug_settings.gd")
	var _average_disabled: bool = false
	var _midpoint_disabled: bool = false
	var _graph_disabled: bool = false
	
	var track_type: TiDeTrackType = null
	
	
	func _init(p_value: Variant) -> void:
		value = p_value
		track_type = TickDebug._find_track_type(p_value)
		
		_average_disabled = _settings.get_disable_average()
		_midpoint_disabled = _settings.get_disable_midpoint()
		_graph_disabled = _settings.get_disable_graph()
		
		if track_type == null:
			return
		
		if track_type.supports_numeric():
			min_value = p_value
			max_value = p_value
			midpoint_value = p_value
			average = p_value
			total_sum = track_type.zero_value()
			total_count = track_type.zero_value()
	
	
	func update(p_value: Variant) -> void:
		value = p_value
		
		if track_type == null:
			return
		
		if track_type.supports_numeric():
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
			track_type.calc_midpoint(min_value, max_value)
		
		if !_average_disabled:
			average = track_type.calc_average(self)
	
	
	## Safe accessor to [method TiDeTrackType.supports_numeric] of this Data's
	## TrackType.
	func supports_numeric() -> bool:
		if track_type == null:
			return false
		return track_type.supports_numeric()
	
	
	## Safe accessor to [method TiDeTrackType.format] of this Data's TrackType.
	## Uses [code]str()[/code] if this Data has no TrackType.
	func str_format(p_value: Variant) -> String:
		if track_type != null && p_value != null:
			return track_type.format(p_value)
		return str(p_value)
	
