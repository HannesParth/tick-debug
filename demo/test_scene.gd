extends Control


@export var _float_amount: int = 1
@export var _vector3_amount: int = 1


func _process(_delta: float) -> void:
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
