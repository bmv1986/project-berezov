extends Node3D

var gate_open: bool = false

func _process(delta: float) -> void:
	if gate_open:
		var mesh: MeshInstance3D = $GateMesh
		if mesh:
			mesh.position.y = lerpf(mesh.position.y, 4.0, delta * 2.0)

func open_gate() -> void:
	gate_open = true
