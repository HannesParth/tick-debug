extends Control


@export var _float_amount: int = 1
@export var _vector3_amount: int = 1

@export var _single_test_type: Variant.Type = TYPE_FLOAT


func _process(_delta: float) -> void:
	var single: Variant = _generate_random_value(_single_test_type)
	TickDebug.track(single, self, &"Variable Type")
	
	for i: int in _float_amount:
		var value: float = randf_range(0, 10)
		TickDebug.track(value, self, &"Float #" + str(i + 1))
	
	for i: int in _vector3_amount:
		var value: Vector3 = Vector3(
				randf_range(0, 10),
				randf_range(0, 10),
				randf_range(0, 10)
		)
		TickDebug.track(value, self, &"Vector3 #" + str(i + 1))


func _generate_random_value(p_type: Variant.Type) -> Variant:
	match p_type:
		TYPE_BOOL:
			return bool(randi() % 2)
		TYPE_INT:
			return randi_range(-100, 100)
		TYPE_FLOAT:
			return randf_range(-100.0, 100.0)
		TYPE_STRING:
			return "random_" + str(randi_range(0, 9999))
		TYPE_VECTOR2:
			return Vector2(
					randf_range(-100.0, 100.0), 
					randf_range(-100.0, 100.0)
			)
		TYPE_VECTOR3:
			return Vector3(
					randf_range(-100.0, 100.0), 
					randf_range(-100.0, 100.0), 
					randf_range(-100.0, 100.0)
			)
		TYPE_COLOR:
			return Color(randf(), randf(), randf(), 1.0)
		_:
			push_warning("No random value implemented for this type")
			return 0.0
