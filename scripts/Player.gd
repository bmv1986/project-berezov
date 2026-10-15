extends CharacterBody3D

# --- Настройки физики и скорости ---
@export var walk_speed := 5.0
@export var sprint_speed := 8.5
@export var jump_velocity := 4.5
@export var acceleration := 12.0   # Плавность разгона
@export var deceleration := 15.0   # Плавность торможения

# --- Настройки камеры ---
@export var mouse_sensitivity := 0.002
@export var camera_pitch_limit := 1.2 # Ограничение наклона камеры вверх/вниз (в радианах)

# Гравитация берется из настроек проекта
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D

func _ready() -> void:
	# Захватываем курсор мыши при старте игры
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	# Освобождение/захват курсора по клавише Escape
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Обработка движения мыши
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Вращаем персонажа по горизонтали (ось Y)
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		# Вращаем камеру по вертикали (ось X)
		camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		# Ограничиваем наклон, чтобы камера не перевернулась
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -camera_pitch_limit, camera_pitch_limit)

func _physics_process(delta: float) -> void:
	# 1. Гравитация
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 2. Прыжок (Пробел)
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# 3. Расчет направления движения (относительно камеры)
	# ui_left/right/up/down по умолчанию это A/D/W/S
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Получаем векторы "вперед" и "вправо" от глобального положения камеры
	var forward = camera.global_transform.basis.z
	var right = camera.global_transform.basis.x
	
	# Обнуляем ось Y, чтобы наклон камеры не заставлял персонажа лететь в небо
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()
	
	# Итоговый вектор движения
	var direction = (forward * -input_dir.y + right * input_dir.x).normalized()

	# 4. Применение скорости (Спринт по Shift)
	var current_speed = walk_speed
	if Input.is_key_pressed(KEY_SHIFT):
		current_speed = sprint_speed
		
	var target_velocity = direction * current_speed
	
	# Выбираем коэффициент: ускорение при движении, торможение при отпускании клавиш
	var accel = acceleration if input_dir != Vector2.ZERO else deceleration
	
	# Плавно изменяем скорость (lerp)
	velocity.x = lerp(velocity.x, target_velocity.x, accel * delta)
	velocity.z = lerp(velocity.z, target_velocity.z, accel * delta)

	# 5. Поворот модели персонажа в сторону движения
	if direction != Vector3.ZERO:
		var target_angle = atan2(direction.x, direction.z)
		# lerp_angle обеспечивает плавный поворот модели
		rotation.y = lerp_angle(rotation.y, target_angle, 10.0 * delta)

	# 6. Применяем движение
	move_and_slide()
