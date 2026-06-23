@tool
extends TiDeTrackType



func get_type() -> Variant:
	return TYPE_STRING


func format(p_value: Variant) -> String:
	return p_value


func random_value() -> Variant:
	return "random_" + str(randi_range(0, 9999))


func supports_numeric() -> bool:
	return false


func zero_value() -> Variant:
	return ""


func calc_average(_p_history: Array[Variant]) -> Variant:
	return false


func calc_midpoint(_p_min: Variant, _p_max: Variant) -> Variant:
	return false
