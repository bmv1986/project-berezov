extends CharacterBody3D

signal charging_zone_reached(is_charging: bool)
signal robot_camera_discovered()

@export var max_speed: float = 4.0
@export var acceleration: float = 10.0
@export var turn_speed: float = 2.5
@export var charging_distance: float = 2.0

var current_speed: float = 0.0
var current_turn: float = 0.0
var is_active: bool = false
var is_charging: bool = false
var power_zone: Node3D = null
var robot_camera: Camera3D = null
var camera_notified: bool = false

# Гравитация из настроек проекта (как у рабочего персонажа)
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func set_active(active: bool) -> void:
	is_active = active
	if not active:
		current_speed = 0.0
		current_turn = 0.0

func _ready() -> void:
	print(">>> Robot _ready() вызван")
	print(">>> Начальная позиция: ", global_position)
	print(">>> is_on_floor(): ", is_on_floor())
	
	# Ждём 1 кадр чтобы физика обновилась
	await get_tree().process_frame
	
	print(">>> После 1 кадра is_on_floor(): ", is_on_floor())
	print(">>> После 1 кадра позиция: ", global_position)
	
	# Если всё ещё не на полу — поднимаем
	if not is_on_floor():
		global_position.y += 1.0
		await get_tree().process_frame
		print(">>> После поднятия позиция: ", global_position.y)
	
	# Ищем зону зарядки
	power_zone = get_node_or_null("../Power")
	if power_zone == null:
		power_zone = get_node_or_null("../../Power")
	if power_zone == null:
		var zones := get_tree().get_nodes_in_group("charging_zone")
		if zones.size() > 0:
			power_zone = zones[0]
	
	if power_zone:
		print(">>> Зона зарядки найдена: ", power_zone.name)
	else:
		print(">>> ВНИМАНИЕ: зона зарядки НЕ найдена!")
	
	# Ищем камеру робота
	robot_camera = get_node_or_null("Robot/Camera3")
	if robot_camera == null:
		robot_camera = get_node_or_null("Camera3")
	
	if robot_camera:
		robot_camera.current = false
		print(">>> Камера робота найдена: ", robot_camera.name)
	else:
		print(">>> ВНИМАНИЕ: камера робота НЕ найдена!")

func _physics_process(delta: float) -> void:
	# === ГРАВИТАЦИЯ ТОЛЬКО В ВОЗДУХЕ (как у рабочего персонажа) ===
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if is_active and not get_tree().paused:
		# Проверка зоны зарядки
		if power_zone and not camera_notified:
			var distance := global_position.distance_to(power_zone.global_position)
			if distance <= charging_distance:
				if not is_charging:
					is_charging = true
					charging_zone_reached.emit(true)
					print(">>> РОБОТ НА ЗОНЕ ЗАРЯДКИ, расстояние: ", distance)
				if robot_camera:
					camera_notified = true
					robot_camera_discovered.emit()
					print(">>> КАМЕРА РОБОТА ОБНАРУЖЕНА!")
			else:
				if is_charging:
					is_charging = false
					charging_zone_reached.emit(false)
		elif power_zone == null and not camera_notified:
			print(">>> ВНИМАНИЕ: зона зарядки не найдена!")
			camera_notified = true

		# Обработка ввода
		var target_speed: float = 0.0
		var target_turn: float = 0.0

		if Input.is_key_pressed(KEY_W):
			target_speed = max_speed
		elif Input.is_key_pressed(KEY_S):
			target_speed = -max_speed * 0.6

		if Input.is_key_pressed(KEY_A):
			target_turn = turn_speed
		elif Input.is_key_pressed(KEY_D):
			target_turn = -turn_speed

		# Плавное изменение скорости
		current_speed = lerp(current_speed, target_speed, acceleration * delta)
		current_turn = lerp(current_turn, target_turn, turn_speed * 3.0 * delta)

		# Поворот
		if abs(current_turn) > 0.01:
			rotate_y(current_turn * delta)

		# Движение по горизонтали (как у рабочего персонажа — lerp по X и Z)
		if abs(current_speed) > 0.01:
			var forward_direction: Vector3 = -global_transform.basis.z
			velocity.x = lerp(velocity.x, forward_direction.x * current_speed, acceleration * delta)
			velocity.z = lerp(velocity.z, forward_direction.z * current_speed, acceleration * delta)
		else:
			velocity.x = lerp(velocity.x, 0.0, acceleration * delta)
			velocity.z = lerp(velocity.z, 0.0, acceleration * delta)
	
	# Применяем движение
	move_and_slide()

func get_robot_camera() -> Camera3D:
	return robot_camera

func is_at_charging_zone() -> bool:
	return is_charging
