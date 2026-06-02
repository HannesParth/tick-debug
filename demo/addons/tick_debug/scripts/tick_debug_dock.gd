@tool
@abstract
class_name TiDeDock
extends PanelContainer


@export var property_element_scene: PackedScene
@export var properties_container: VBoxContainer
@export var no_properties_disclaimer: Label


var _elements: Dictionary[String, TiDePropertyElement] = {}


func _enter_tree() -> void:
	_clear_children()


func _exit_tree() -> void:
	_clear_children()


func _ready() -> void:
	TickDebug._property_untracked.connect(on_untracked)


func on_untracked(p_id: String) -> void:
	if !_elements.has(p_id):
		return
	_elements[p_id].queue_free()
	_elements.erase(p_id)
	_refresh_disclaimer()


## Updates a property entry. [br]
## Called by the DebuggerPlugin for the editor dock. [br]
## Called in _process() for the runtime dock.
func update_entry(p_id: String, p_data: TickDebug.ValueData) -> void:
	if !p_data:
		return
	
	if _elements.has(p_id):
		_elements[p_id].update(p_data)
		return
	
	var ele: TiDePropertyElement = _create_property_element(p_id, p_data)
	_elements[p_id] = ele


func _create_property_element(
		p_id: String, 
		p_data: TickDebug.ValueData
) -> TiDePropertyElement:
	var inst: TiDePropertyElement= property_element_scene.instantiate()
	inst.setup(p_id, p_data)
	properties_container.add_child(inst)
	return inst


func _clear_children() -> void:
	for child: Node in properties_container.get_children():
		child.queue_free()


func _refresh_disclaimer() -> void:
	no_properties_disclaimer.visible = _elements.is_empty()
