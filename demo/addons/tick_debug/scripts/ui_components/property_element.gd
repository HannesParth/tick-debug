@tool
class_name TiDePropertyElement
extends Control
## A list element of a [TiDeDock], displaying info for 1 value.
##
## Enables and disables value displays depending on the value type. [br]
## Any disabled UI Nodes also have their processing disabled.


@export var _property_title_value: TiDeTitleValuePair

@export var _color_display_rect: ColorRect

@export_group("Snapshots Refs")
@export var _snapshots_foldable: FoldableContainer
@export var _min_value: TiDeTitleValuePair
@export var _max_value: TiDeTitleValuePair
@export var _midpoint_value: TiDeTitleValuePair
@export var _average_value: TiDeTitleValuePair

@export_group("Graph Refs")
@export var _graph_foldable: FoldableContainer
@export var _graph: TiDeGraphSimple


var custom_id: String

@warning_ignore("inferred_declaration")
var _settings := preload("res://addons/tick_debug/scripts/tick_debug_settings.gd")

# The snapshots foldable does not get updated while it is folded.
# If the user stop updating this value and then unfolds the foldable,
# it would show zero-values.
# Here we cache the last unset value update to the snapshots and apply it
# when the foldable is unfolded.
var _last_unset_min: Variant
var _last_unset_max: Variant
var _last_unset_midpoint: Variant
var _last_unset_average: Variant


func setup(p_custom_id: String, p_data: TickDebug.ValueData) -> void:
	custom_id = p_custom_id
	
	_property_title_value.set_title(p_custom_id.split("::")[1])
	update(p_data)
	
	# --- Set up numeric foldables ---
	_snapshots_foldable.folded = true
	_graph_foldable.folded = true
	
	_snapshots_foldable.folding_changed.connect(
			_on_folding_changed.bind(_snapshots_foldable)
	)
	# We don't connect the graph foldable, because disabling its processing
	# would stop the graph from keeping its value history.
	
	if _settings.get_disable_snapshots() || !p_data.supports_numeric():
		_snapshots_foldable.hide()
		_snapshots_foldable.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		if _settings.get_disable_average():
			_average_value.hide()
			_average_value.process_mode = Node.PROCESS_MODE_DISABLED
		if _settings.get_disable_midpoint():
			_midpoint_value.hide()
			_midpoint_value.process_mode = Node.PROCESS_MODE_DISABLED
	
	# --- Set up graph ---
	if _settings.get_disable_graph() || !_graph.try_setup(p_data):
		_graph_foldable.hide()
		_graph_foldable.process_mode = Node.PROCESS_MODE_DISABLED


func update(p_data: TickDebug.ValueData) -> void:
	_property_title_value.set_value(p_data.str_format(p_data.value))
	
	_color_display_rect.visible = typeof(p_data.value) == TYPE_COLOR
	if _color_display_rect.visible:
		_color_display_rect.color = p_data.value
	
	# Format and set values when visible
	if _snapshots_foldable.visible && !_snapshots_foldable.folded:
		_min_value.set_value(p_data.str_format(p_data.min_value))
		_max_value.set_value(p_data.str_format(p_data.max_value))
		
		# If not hidden because of setting, see setup
		if _midpoint_value.visible:
			_midpoint_value.set_value(p_data.str_format(p_data.midpoint_value))
		if _average_value.visible:
			_average_value.set_value(p_data.str_format(p_data.average))
	
	# Otherwise, cache values for eventual unfolding
	else:
		_last_unset_min = p_data.min_value
		_last_unset_max = p_data.max_value
		if _midpoint_value.visible:
			_last_unset_midpoint = p_data.midpoint_value
		if _average_value.visible:
			_last_unset_average = p_data.average
	
	if _graph_foldable.visible:
		_graph.update(p_data.value)


func _on_folding_changed(
		p_is_folded: bool, 
		p_foldable: FoldableContainer
) -> void:
	for child: Node in p_foldable.get_children():
		child.process_mode = (
				Node.PROCESS_MODE_DISABLED 
				if p_is_folded 
				else Node.PROCESS_MODE_INHERIT
		)
	
	if !p_is_folded:
		if _last_unset_min != null:
			_min_value.set_value(TickDebug._format_value(_last_unset_min))
		if _last_unset_max != null:
			_max_value.set_value(TickDebug._format_value(_last_unset_max))
		
		# If not hidden because of setting, see setup
		if _midpoint_value.visible && _last_unset_midpoint != null:
			_midpoint_value.set_value(TickDebug._format_value(_last_unset_midpoint))
		if _average_value.visible && _last_unset_average != null:
			_average_value.set_value(TickDebug._format_value(_last_unset_average))
