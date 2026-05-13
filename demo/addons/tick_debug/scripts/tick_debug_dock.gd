@tool
class_name TiDiEditorDock
extends Control


@export var property_element_scene: PackedScene
@export var properties_container: VBoxContainer
@export var no_properties_disclaimer: Label


var _elements: Dictionary[String, TiDePropertyElement] = {}
var _is_runtime: bool = false


func _enter_tree() -> void:
	_clear_children()


func _exit_tree() -> void:
	_clear_children()


func _ready() -> void:
	TickDebug._property_untracked.connect(on_untracked)


func _on_runtime_started() -> void:
	_is_runtime = true
	_elements.clear()
	_clear_children()


func _on_runtime_stopped() -> void:
	_is_runtime = false
	_sync_from_editor_autoload()


func _sync_from_editor_autoload() -> void:
	_elements.clear()
	_clear_children()
	
	for id: String in TickDebug._tracked_properties:
		update_entry(id, TickDebug._tracked_properties[id])
	_refresh_disclaimer()


func on_untracked(p_id: String) -> void:
	if !_elements.has(p_id):
		return
	_elements[p_id].queue_free()
	_elements.erase(p_id)
	_refresh_disclaimer()


func _process(_p_delta: float) -> void:
	if !Engine.is_editor_hint():
		return
	
	_refresh_disclaimer()
	if !TickDebug._new_track:
		return
	
	for id: String in TickDebug._tracked_properties:
		update_entry(id, TickDebug._tracked_properties[id])
	
	TickDebug._new_track = false


func update_entry(p_id: String, p_value: Variant) -> void:
	if _elements.has(p_id):
		_elements[p_id].update(p_value)
		return
	
	var ele: TiDePropertyElement = _create_property_element(p_id, p_value)
	_elements[p_id] = ele


func _create_property_element(p_id: String, p_value: Variant) -> TiDePropertyElement:
	var inst: TiDePropertyElement= property_element_scene.instantiate()
	inst.setup(p_id, p_value)
	properties_container.add_child(inst)
	return inst


func _clear_children() -> void:
	for child: Node in properties_container.get_children():
		child.queue_free()


func _refresh_disclaimer() -> void:
	no_properties_disclaimer.visible = _elements.is_empty()
