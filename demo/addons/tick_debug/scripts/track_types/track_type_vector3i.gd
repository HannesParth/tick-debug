@tool
extends TiDeTrackType



func get_type() -> Variant:
	return TYPE_VECTOR3I


func format(p_value: Variant) -> String:
	# Pad to 4 chars
	return "(%4d, %4d, %4d)" % [p_value.x, p_value.y, p_value.z]


func random_value() -> Variant:
	return Vector3i(
			randi_range(-10, 10),
			randi_range(-10, 10),
			randi_range(-10, 10)
	)


func supports_numeric() -> bool:
	return true


func zero_value() -> Variant:
	return Vector3i.ZERO


func calc_average(p_history: Array[Variant]) -> Variant:
	if p_history.is_empty():
		return 0.0
	
	var sum: Vector3i = zero_value()
	var count: int = p_history.size()
	
	for entry: Vector3i in p_history:
		sum += entry
	
	return sum / float(count)


func calc_midpoint(p_min: Variant, p_max: Variant) -> Variant:
	return (p_min + p_max) / 2
