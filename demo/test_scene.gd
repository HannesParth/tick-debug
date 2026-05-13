extends Control

var test: int = 0

func _process(_delta: float) -> void:
	test += 1
	TickDebug.track(test, self, "process-test")
