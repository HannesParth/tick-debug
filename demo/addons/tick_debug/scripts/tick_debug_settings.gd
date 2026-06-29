extends RefCounted
# Reference by using 
# preload("res://addons/tick_debug/scripts/tick_debug_settings.gd")
# to reduce usage of class names.


const KEY_BASE: String = "debug/tick_debug"

const KEY_DISABLE_AVERAGE: String = "%s/disable_average" % KEY_BASE
const KEY_DISABLE_MIDPOINT: String = "%s/disable_midpoint" % KEY_BASE
const KEY_DISABLE_SNAPSHOTS: String = "%s/disable_snapshots" % KEY_BASE
const KEY_DISABLE_GRAPH: String = "%s/disable_graph" % KEY_BASE
const KEY_DISABLE_EDITOR_DOCK: String = "%s/disable_editor_dock" % KEY_BASE

const KEY_VALUE_HISTORY_SIZE: String = "%s/value_history_size" % KEY_BASE
const KEY_MAX_DEBUGGER_MSG_PER_SEC: String = \
		"%s/max_debugger_messages_per_second" % KEY_BASE

const KEY_DEFAULTS: Dictionary[String, Variant] = {
	KEY_DISABLE_AVERAGE: false,
	KEY_DISABLE_MIDPOINT: false,
	KEY_DISABLE_SNAPSHOTS: false,
	KEY_DISABLE_GRAPH: false,
	KEY_DISABLE_EDITOR_DOCK: false,
	KEY_VALUE_HISTORY_SIZE: 300,
	KEY_MAX_DEBUGGER_MSG_PER_SEC: 6144
}

const DESCRIPTIONS: Dictionary[String, String] = {
	KEY_DISABLE_AVERAGE: 
		"Disable the display and calculation of average values.",
	KEY_DISABLE_MIDPOINT:
		"Disable the display and calculation of midpoint values",
	KEY_DISABLE_SNAPSHOTS:
		"Disable the display and calculation of all snapshots, "
		+ "including the average.",
	KEY_DISABLE_GRAPH:
		"Disable the display and calculation of the simple value history graph.",
	KEY_DISABLE_EDITOR_DOCK:
		"Disable the TickDebug editor dock. 
		This also disables the DebuggerPlugin, stopping the TickDebug addon "
		+ "from sending messages using the EngineDebugger for each value.
		This may even noticably improve performance in the editor.",
	KEY_VALUE_HISTORY_SIZE:
		"Size of the history array of tracked values with a graph.
		Determines the display window of a graph.
		Currently, the simple graph supports floats and ints.",
	KEY_MAX_DEBUGGER_MSG_PER_SEC:
		"TickDebug uses EngineDebugger.send_message to carry runtime values "
		+ "to the editor. This message queue has a max size.
		Exceeding this size triggers errors. To prevent these errors, TickDebug "
		+ "has this separate limit."
}


static func initialize_setting(
		key: String, 
		default_value: Variant, 
		type: int, 
		hint: int = PROPERTY_HINT_NONE, 
		hint_string: String = ""
) -> void:
	init_description_workaround(key)
	
	if not ProjectSettings.has_setting(key):
		ProjectSettings.set(key, default_value)
	ProjectSettings.set_initial_value(key, default_value)
	ProjectSettings.add_property_info({name=key, type=type, hint=hint, hint_string=hint_string})


# As of Godot 4.6.3, setting a description tooltip for custom project 
# settings is not possible.
# So, I am testing the workaround of adding the descriptions as settings in the
# form of (multiline) Strings.
static func init_description_workaround(actual_setting_key: String) -> void:
	var key: String = actual_setting_key + "_description"
	var value: String = DESCRIPTIONS[actual_setting_key]
	ProjectSettings.set(key, value)
	ProjectSettings.set_initial_value(key, value)
	
	if value.length() > 80:
		ProjectSettings.add_property_info({
			name=key, 
			type=TYPE_STRING, 
			hint=PROPERTY_HINT_MULTILINE_TEXT
		})
	else:
		ProjectSettings.add_property_info({
			name=key, 
			type=TYPE_STRING
		})


static func setup_settings() -> void:
	initialize_setting(
			KEY_DISABLE_AVERAGE, 
			KEY_DEFAULTS[KEY_DISABLE_AVERAGE],
			TYPE_BOOL
	)
	initialize_setting(
			KEY_DISABLE_MIDPOINT,
			KEY_DEFAULTS[KEY_DISABLE_MIDPOINT],
			TYPE_BOOL
	)
	initialize_setting(
			KEY_DISABLE_SNAPSHOTS, 
			KEY_DEFAULTS[KEY_DISABLE_SNAPSHOTS],
			TYPE_BOOL
	)
	initialize_setting(
			KEY_DISABLE_GRAPH, 
			KEY_DEFAULTS[KEY_DISABLE_GRAPH],
			TYPE_BOOL
	)
	initialize_setting(
			KEY_DISABLE_EDITOR_DOCK,
			KEY_DEFAULTS[KEY_DISABLE_EDITOR_DOCK],
			TYPE_BOOL
	)
	initialize_setting(
			KEY_VALUE_HISTORY_SIZE, 
			KEY_DEFAULTS[KEY_VALUE_HISTORY_SIZE],
			TYPE_INT,
			PROPERTY_HINT_RANGE,
			"10,2400,10,or_greater,prefer_slider,suffix:values"
	)
	initialize_setting(
			KEY_MAX_DEBUGGER_MSG_PER_SEC,
			KEY_DEFAULTS[KEY_MAX_DEBUGGER_MSG_PER_SEC],
			TYPE_INT,
			PROPERTY_HINT_RANGE,
			"2048,10240,8,or_greater,prefer_slider,suffix:per sec"
	)


static func get_disable_average() -> bool:
	return ProjectSettings.get_setting(
			KEY_DISABLE_AVERAGE, 
			KEY_DEFAULTS[KEY_DISABLE_AVERAGE]
	)


static func get_disable_midpoint() -> bool:
	return ProjectSettings.get_setting(
			KEY_DISABLE_MIDPOINT,
			KEY_DEFAULTS[KEY_DISABLE_MIDPOINT]
	)


static func get_disable_snapshots() -> bool:
	return ProjectSettings.get_setting(
			KEY_DISABLE_SNAPSHOTS, 
			KEY_DEFAULTS[KEY_DISABLE_SNAPSHOTS]
	)


static func get_disable_graph() -> bool:
	return ProjectSettings.get_setting(
			KEY_DISABLE_GRAPH, 
			KEY_DEFAULTS[KEY_DISABLE_GRAPH]
	)


static func get_disable_editor_dock() -> bool:
	return ProjectSettings.get_setting(
			KEY_DISABLE_EDITOR_DOCK,
			KEY_DEFAULTS[KEY_DISABLE_EDITOR_DOCK]
	)


static func get_value_history_size() -> int:
	return ProjectSettings.get_setting(
			KEY_VALUE_HISTORY_SIZE, 
			KEY_DEFAULTS[KEY_VALUE_HISTORY_SIZE]
	)


static func get_max_debugger_msg_per_sec() -> int:
	return ProjectSettings.get_setting(
			KEY_MAX_DEBUGGER_MSG_PER_SEC,
			KEY_DEFAULTS[KEY_MAX_DEBUGGER_MSG_PER_SEC]
	)
