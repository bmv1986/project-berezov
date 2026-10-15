extends CharacterBody3D

const SPEED := 6.0
const JUMP_VELOCITY := 6.5
const GRAVITY := 18.0

@onready var camera: Camera3D = null

var yaw := 0.0
var pitch := -0.75

func _ready():
    # Find camera safely (it should be a child named "Camera3D")
    if has_node("Camera3D"):
        camera = $Camera3D
    else:
        push_warning("Player: Camera3D node not found as child of Player. Camera controls will be disabled.")

    # Capture mouse for gameplay (won't crash if not available)
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
    # Ensure velocity exists
    if not Engine.has_singleton("PhysicsServer3D") and not has_meta("_velocity_initialized"):
        # Just in case, initialize velocity
        velocity = Vector3.ZERO
        set_meta("_velocity_initialized", true)

    var input_dir := Vector2(
        Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
        Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
    )

    var direction := Vector3.ZERO
    if input_dir.length() > 0.0:
        input_dir = input_dir.normalized()
        var forward := -transform.basis.z
        var right := transform.basis.x
        direction = (right * input_dir.x + forward * input_dir.y).normalized()
        velocity.x = direction.x * SPEED
        velocity.z = direction.z * SPEED
    else:
        velocity.x = lerp(velocity.x, 0.0, 0.15)
        velocity.z = lerp(velocity.z, 0.0, 0.15)

    if not is_on_floor():
        velocity.y -= GRAVITY * delta
    elif Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = JUMP_VELOCITY

    # Move using CharacterBody3D helper
    move_and_slide()

func _input(event):
    # Mouse look
    if event is InputEventMouseMotion:
        yaw -= event.relative.x * 0.005
        pitch -= event.relative.y * 0.005
        pitch = clamp(pitch, -1.3, 1.3)

        rotation.y = yaw
        if camera:
            camera.rotation.x = pitch

    # ESC release mouse
    if event is InputEventKey and event.pressed:
        # Use Key enum when available (Godot 4)
        var esc_pressed := false
        if "keycode" in event:
            esc_pressed = event.keycode == Key.ESCAPE
        else:
            esc_pressed = event.scancode == KEY_ESCAPE

        if esc_pressed:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
