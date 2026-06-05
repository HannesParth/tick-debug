extends Control


var test: float = 0
var test_vector: Vector2 = Vector2.ZERO


func _process(_delta: float) -> void:
	test = randf_range(0.0, 10.0)
	TickDebug.track(test, self, "process-test")
	
	test_vector += Vector2.ONE
	TickDebug.track(test_vector, self, "Test Vector")
