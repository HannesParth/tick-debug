extends Control


@export var float_amount: int = 100


func _process(_delta: float) -> void:
	for i: int in float_amount:
		var value: float = randf()
		TickDebug.track(value, self, "Value #%s" % (i + 1))


# Testing with Profiler, Measure: Average Time (ms)
# Running performance_test scene ~5 sec per test

# Draw based implementation
# Test #1: 100 values
# - Frame Time: 		~3.59ms
# - Script Functions: 	~2.89ms
# - _draw: 				~2.77ms
# - _process: 			~0.40ms
#
# Test #2: 1000 values
# - Frame Time: 		~34.4ms
# - Script Functions: 	~28.77ms
# - _draw: 				~27.90ms
# - _process: 			~4.20ms

# Node based implementation
# (using TickDebugDock subscene in performance_test scene)
# Test #1: 100 values
# - Frame Time: 		~2.29ms
# - Script Functions: 	~0.47ms
# - _draw: 				none
# - _process: 			~0.42ms
#
# Test #2: 1000 values
# - Frame Time: 		~22.69ms
# - Script Functions: 	~4.88ms
# - _draw: 				none
# - _process: 			~4.49ms
