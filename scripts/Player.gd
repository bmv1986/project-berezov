extends CharacterBody3D

@export var SPEED: float = 6.0
@export var JUMP_VELOCITY: float = 6.5
@export var GRAVITY: float = 18.0

var velocity: Vector3 = Vector3.ZERO

onready var camera: Camera3D = get_node_or_null("Camera3D")

var yaw: float = 0.0
var pitch: float = 0.0

func _ready() -> void:
    if camera == null:
        push_warning("Player: Camera3D child not found — camera control disabled.")
    # Capture mouse for gameplay (skip when running in editor)
    if not Engine.is_editor_hint():
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
    # Movement input (WASD)
    var input_dir := Vector2(
        Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
        Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
    )

    var dir_world := Vector3.ZERO
    if input_dir.length() > 0.0:
        input_dir = input_dir.normalized()
        # movement relative to player yaw (first-person)
        var forward := -transform.basis.z
        forward.y = 0
        forward = forward.normalized()
        var right := transform.basis.x
        right.y = 0
        right = right.normalized()
        dir_world = (right * input_dir.x + forward * input_dir.y).normalized()
        velocity.x = dir_world.x * SPEED
        velocity.z = dir_world.z * SPEED
    else:
        velocity.x = lerp(velocity.x, 0.0, 0.15)
        velocity.z = lerp(velocity.z, 0.0, 0.15)

    # Gravity and jump
    if not is_on_floor():
        velocity.y -= GRAVITY * delta
    elif Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = JUMP_VELOCITY

    # Move and get resulting velocity
    velocity = move_and_slide(velocity, Vector3.UP)

func _input(event) -> void:
    # Mouse look: yaw rotates body, pitch rotates camera
    if event is InputEventMouseMotion:
        yaw -= event.relative.x * 0.003
        pitch -= event.relative.y * 0.003
        pitch = clamp(pitch, -1.3, 1.3)
        rotation.y = yaw
        if camera:
            camera.rotation.x = pitch

    # ESC to release mouse (use legacy KEY_ESCAPE constant)
    if event is InputEventKey and event.pressed:
        if event.scancode == KEY_ESCAPE:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
