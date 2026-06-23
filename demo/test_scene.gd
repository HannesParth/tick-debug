extends Control


@export var _float_amount: int = 1
@export var _vector3_amount: int = 1

@export var _single_test_type: Variant.Type = TYPE_FLOAT

var _test_track_type: TiDeTrackType = null


func _ready() -> void:
	_test_track_type = TickDebug._track_types.get(_single_test_type)
	if _test_track_type == null:
		printerr("No registered TrackType for the current test type.")


func _process(_delta: float) -> void:
	if _test_track_type == null:
		return
	
	TickDebug.track(_test_track_type.random_value(), self, &"Variable Type")
	
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
