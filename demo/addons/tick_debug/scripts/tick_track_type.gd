@tool
@abstract
class_name TiDeTrackType
extends Resource


@export var builtin_type: Variant.Type


func is_object() -> bool:
	return builtin_type == TYPE_OBJECT


# Return either int (builtin) or string (object, class or script name)
# Necassary for mapping
@abstract
func get_type() -> Variant


@abstract
func format(p_value: Variant) -> String


@abstract
func random_value() -> Variant


# Whether the type supports numeric features, can be used for calculations
@abstract 
func supports_numeric() -> bool


@abstract
func zero_value() -> Variant


@abstract
func calc_average(p_history: Array[Variant]) -> Variant


@abstract
func calc_midpoint(p_min: Variant, p_max: Variant) -> Variant
