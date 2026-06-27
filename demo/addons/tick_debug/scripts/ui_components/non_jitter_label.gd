@tool
extends Label
## A Label that does not instantly decrease in size if something shorter
## than the previous content is entered.


## After how many seconds of the labels horizontal min size being smaller than
## its current horizontal size the label shrinks.
const SHRINK_AFTER_SEC: float = 3.0

## How much smaller the labels horizontal min size has to be compared to its 
## current horizontal size to consider shrinking.
const SIZE_DELTA_THRESHOLD: float = 10.0


var _sec_since_size_increase: float = 0.0
var _shrink_tween: Tween = null
var _start_min_size: Vector2


func _init() -> void:
	_start_min_size = custom_minimum_size
	minimum_size_changed.connect(_on_minimum_size_changed)


func _process(delta: float) -> void:
	_sec_since_size_increase += delta
	
	var min_x: float = get_minimum_size().x
	if (
			_sec_since_size_increase > SHRINK_AFTER_SEC 
			&& custom_minimum_size.x > _start_min_size.x
			&& custom_minimum_size.x > min_x + SIZE_DELTA_THRESHOLD
			&& (_shrink_tween == null || !_shrink_tween.is_running())
	):
		var target: float = maxf(_start_min_size.x, min_x)
		_kill_tween()
		_shrink_tween = create_tween()
		_shrink_tween.tween_property(
				self, 
				"custom_minimum_size",
				Vector2(target, 0), 
				0.8
		)


func _on_minimum_size_changed() -> void:
	var min_x: float = get_minimum_size().x
	
	if min_x > custom_minimum_size.x:
		custom_minimum_size.x = min_x
		_sec_since_size_increase = 0.0
		_kill_tween()


func _kill_tween() -> void:
	if _shrink_tween != null:
		_shrink_tween.kill()
