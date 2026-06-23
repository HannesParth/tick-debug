@tool
extends TiDeTrackType



func get_type() -> Variant:
	return TYPE_FLOAT


func format(p_value: Variant) -> String:
	return "%.2f" % p_value


func random_value() -> Variant:
	return randf_range(-10.0, 10.0)


func supports_numeric() -> bool:
	return true


func zero_value() -> Variant:
	return 0.0


func calc_average(p_history: Array[Variant]) -> Variant:
	if p_history.is_empty():
		return 0.0
	
	var sum: float = zero_value()
	var count: int = p_history.size()
	
	for entry: float in p_history:
		sum += entry
	
	return sum / float(count)


func calc_midpoint(p_min: Variant, p_max: Variant) -> Variant:
	return (p_min + p_max) / 2
