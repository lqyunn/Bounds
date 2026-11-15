extends Node

signal bounced(new_count: int)

var bounce_count: int = 0


func register_bounce() -> void:
	bounce_count += 1
	bounced.emit(bounce_count)
