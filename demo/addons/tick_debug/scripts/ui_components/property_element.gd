@tool
class_name TiDePropertyElement
extends Control


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
	_graph_foldable.folding_changed.connect(
			_on_folding_changed.bind(_graph_foldable)
	)
	
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
	if (
			_settings.get_disable_graph()
			|| !_graph.try_setup(p_data) 
	):
		_graph_foldable.hide()
		_graph_foldable.process_mode = Node.PROCESS_MODE_DISABLED


func update(p_data: TickDebug.ValueData) -> void:
	_property_title_value.set_value(p_data.value)
	
	_color_display_rect.visible = p_data.is_color()
	if _color_display_rect.visible:
		_color_display_rect.color = p_data.value
	
	if _snapshots_foldable.visible && !_snapshots_foldable.folded:
		_min_value.set_value(p_data.min_value)
		_max_value.set_value(p_data.max_value)
		
		# If not hidden because of setting, see setup
		if _midpoint_value.visible:
			_midpoint_value.set_value(p_data.midpoint_value)
		if _average_value.visible:
			_average_value.set_value(p_data.average)
	
	if _graph_foldable.visible && !_graph_foldable.folded:
		_graph.update()


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
