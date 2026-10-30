extends Node3D

var gate_open: bool = false
var gate_mesh: Node3D = null

func _ready() -> void:
	# Ищем меш один раз при старте
	gate_mesh = get_node_or_null("GateMesh")
	if gate_mesh == null:
		# Если GateMesh нет — используем саму ноду gate
		gate_mesh = self

func _process(_delta: float) -> void:
	# Ничего не делаем в process — вся логика в open_gate()
	pass

func open_gate() -> void:
	if gate_open:
		return
	gate_open = true
	
	if gate_mesh:
		var tween := create_tween()
		tween.tween_property(gate_mesh, "position:y", gate_mesh.position.y + 4.0, 1.5).set_ease(Tween.EASE_IN_OUT)

func open_gate_instantly() -> void:
	if gate_open:
		return
	gate_open = true
	
	if gate_mesh:
		gate_mesh.position.y += 4.0

func is_open() -> bool:
	return gate_open
