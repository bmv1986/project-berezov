extends Node3D

var gate_open: bool = false

func _ready() -> void:
	pass

func open_gate() -> void:
	var gate = get_node_or_null("bunker/bunker2/gate")
	if gate:
		if gate_open:
			return
		gate_open = true
		var tween := create_tween()
		tween.tween_property(gate, "position:y", gate.position.y + 4.0, 1.5).set_ease(Tween.EASE_OUT)

# Мгновенно открывает ворота без анимации (для dual mode)
func open_gate_instantly() -> void:
	var gate = get_node_or_null("bunker/bunker2/gate")
	if gate:
		gate_open = true
		gate.position.y += 4.0
