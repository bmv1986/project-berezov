extends Node3D

var gate_open: bool = false

func open_gate() -> void:
	if gate_open:
		return
	gate_open = true
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y + 4.0, 1.5).set_ease(Tween.EASE_IN_OUT)

func open_gate_instantly() -> void:
	if gate_open:
		return
	gate_open = true
	position.y += 4.0

func is_open() -> bool:
	return gate_open
