extends RefCounted
# Reference by using 
# preload("res://addons/tick_debug/scripts/tick_debug_settings.gd")


const KEY_BASE: String = "debug/tick_debug"

const KEY_DISABLE_AVERAGE: String = "%s/disable_average" % KEY_BASE
const KEY_DISABLE_SNAPSHOTS: String = "%s/disable_snapshots" % KEY_BASE
const KEY_DISABLE_GRAPH: String = "%s/disable_graph" % KEY_BASE
const KEY_DISABLE_EDITOR_DOCK: String = "%s/disable_editor_dock" % KEY_BASE

## Max size of the history of a value, used for calculating the average
## and graph display.
const KEY_VALUE_HISTORY_SIZE: String = "%s/value_history_size" % KEY_BASE

const KEY_DEFAULTS: Dictionary[String, Variant] = {
	KEY_DISABLE_AVERAGE: false,
	KEY_DISABLE_SNAPSHOTS: false,
	KEY_DISABLE_GRAPH: false,
	KEY_DISABLE_EDITOR_DOCK: false,
	KEY_VALUE_HISTORY_SIZE: 150,
}

## FIXME:
## There is currently no way to add descriptions to custom project
## settings. Find another way to show people these descriptions.
const DESCRIPTIONS: Dictionary[String, String] = {
	KEY_DISABLE_AVERAGE: 
		"Disable the display and calculation of average values.",
	KEY_DISABLE_SNAPSHOTS:
		"Disable the display and calculation of all snapshots, "
		+ "including the average.",
	KEY_DISABLE_GRAPH:
		"Disable the display and calculation of the simple value history graph.",
	KEY_DISABLE_EDITOR_DOCK:
		"Disable the TickDebug editor dock. 
		This also disables the DebuggerPlugin, stopping the TickDebug addon "
		+ "from sending messages using the EngineDebugger for each value.
		This quite possibly improves performance in the editor.",
	KEY_VALUE_HISTORY_SIZE:
		"Size of the history array of each tracked value.
		The calculation window of the average and the display window of the "
		+ "graph is determined by this.
		If both average and graph are disabled, no history is kept.",
}


static var values: Dictionary[String, Variant] = {}


static func initialize_setting(
		key: String, 
		default_value: Variant, 
		type: int, 
		hint: int = PROPERTY_HINT_NONE, 
		hint_string: String = ""
) -> void:
	if not ProjectSettings.has_setting(key):
		ProjectSettings.set(key, default_value)
	ProjectSettings.set_initial_value(key, default_value)
	ProjectSettings.add_property_info({name=key, type=type, hint=hint, hint_string=hint_string})


static func setup_settings() -> void:
	initialize_setting(
			KEY_DISABLE_AVERAGE, 
			KEY_DEFAULTS[KEY_DISABLE_AVERAGE],
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
			"10,400,1,or_greater,prefer_slider,suffix:values"
	)


static func rebuild_values() -> void:
	for key: String in KEY_DEFAULTS.keys():
		var val: Variant = ProjectSettings.get_setting(key, KEY_DEFAULTS[key])
		values[key] = val


static func get_disable_average() -> bool:
	var dis: bool = values.get(
			KEY_DISABLE_AVERAGE, 
			KEY_DEFAULTS[KEY_DISABLE_AVERAGE]
	)
	print("Average disabled: ", dis)
	return dis


static func get_disable_snapshots() -> bool:
	return values.get(
			KEY_DISABLE_SNAPSHOTS, 
			KEY_DEFAULTS[KEY_DISABLE_SNAPSHOTS]
	)


static func get_disable_graph() -> bool:
	return values.get(
			KEY_DISABLE_GRAPH, 
			KEY_DEFAULTS[KEY_DISABLE_GRAPH]
	)


static func get_disable_editor_dock() -> bool:
	return values.get(
			KEY_DISABLE_EDITOR_DOCK,
			KEY_DEFAULTS[KEY_DISABLE_EDITOR_DOCK]
	)


static func get_value_history_size() -> int:
	return values.get(
			KEY_VALUE_HISTORY_SIZE, 
			KEY_DEFAULTS[KEY_VALUE_HISTORY_SIZE]
	)
