@tool
extends TiDeTrackType



func get_type() -> Variant:
	return TYPE_COLOR


func format(p_value: Variant) -> String:
	return "(%.2f, %.2f, %.2f, %.2f)" % [p_value.r, p_value.g, p_value.b, p_value.a]


func random_value() -> Variant:
	return Color(randf(), randf(), randf(),randf())


func supports_numeric() -> bool:
	return false


func zero_value() -> Variant:
	return Color.TRANSPARENT


func calc_average(_p_history: Array[Variant]) -> Variant:
	return zero_value()


func calc_midpoint(_p_min: Variant, _p_max: Variant) -> Variant:
	return zero_value()
