@tool
extends TiDeTrackType



func get_type() -> Variant:
	return TYPE_VECTOR2I


func format(p_value: Variant) -> String:
	return "(%4d,\t %4d)" % [p_value.x, p_value.y]


func random_value() -> Variant:
	return Vector2i(
			randi_range(-10, 10),
			randi_range(-10, 10)
	)


func supports_numeric() -> bool:
	return true


func zero_value() -> Variant:
	return Vector2i.ZERO


func calc_average(p_data: TickDebug.ValueData) -> Variant:
	p_data.total_sum += p_data.value
	p_data.total_count += 1
	
	return p_data.total_sum / float(p_data.total_count)


func calc_midpoint(p_min: Variant, p_max: Variant) -> Variant:
	return (p_min + p_max) / 2
