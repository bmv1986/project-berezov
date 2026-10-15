extends CharacterBody3D

const SPEED := 6.0
const JUMP_VELOCITY := 6.5
const GRAVITY := 18.0

@onready var camera: Camera3D = $Camera3D

var yaw := 0.0
var pitch := -0.75

func _ready():
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
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

    move_and_slide()

func _input(event):
    if event is InputEventMouseMotion:
        yaw -= event.relative.x * 0.005
        pitch -= event.relative.y * 0.005
        pitch = clamp(pitch, -1.3, 1.3)

        rotation.y = yaw
        camera.rotation.x = pitch

    if event is InputEventKey and event.pressed and event.scancode == KEY_ESCAPE:
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
