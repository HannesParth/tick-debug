extends Control


var test: int = 0
var test_vector: Vector2 = Vector2.ZERO


func _process(_delta: float) -> void:
	test += 1
	TickDebug.track(test, self, "process-test")
	
	test_vector += Vector2.ONE
	TickDebug.track(test_vector, self, "Test Vector")
