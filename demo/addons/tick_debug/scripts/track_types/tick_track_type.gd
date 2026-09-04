@tool
@abstract
class_name TiDeTrackType
extends RefCounted
## Abstract base class for wrapping types to be usable with TickDebug.
##
## Enforces all functions necessary for a type to be properly tracked. [br]
## Each function's description explains how to use it. [br]
## Look in [code]res://addons/tick_debug/scripts/track_types[/code] for examples.



func is_object() -> bool:
	return get_type() is not int || (get_type() as Variant.Type) == TYPE_OBJECT


## Return either int for builtin [Variant.Type] or string 
## (object, class or script name). [br]
## Necessary for mapping.
@abstract
func get_type() -> Variant;


## Customize the way you want your value to be formatted as a string.
@abstract
func format(p_value: Variant) -> String;


## Return a random value if this type. Used for debugging and testing,
## so returning a stub value here does not affect the normal operation
## of the addon.
@abstract
func random_value() -> Variant;


## Whether the type supports numeric features and can be used for calculations.
@abstract 
func supports_numeric() -> bool;


## Return the zero value of this type. Only relevant for numeric types.
@abstract
func zero_value() -> Variant;


## Return the calculated average of this type. Only relevant for numeric types.
@abstract
func calc_average(p_data: TickDebug.ValueData) -> Variant;


## Return the calculated midpoint of this type. Only relevant for numeric types.
@abstract
func calc_midpoint(p_min: Variant, p_max: Variant) -> Variant;
