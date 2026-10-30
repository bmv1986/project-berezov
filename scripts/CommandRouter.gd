extends Node

signal log_message(text: String)
signal input_mode_changed(mode: String)
signal request_focus()
signal release_focus()
signal hide_signal_screen()
signal show_camera_feed()

# Состояние игры
var devices_scanned: bool = false
var gate_opened: bool = false
var dual_mode: bool = false
var selected_device: int = -1
var previous_input_mode: String = ""
var robot_camera_discovered: bool = false

# Ссылки на объекты мира
var world_scene: Node3D = null
var world_scene2: Node3D = null
var robot: Node3D = null
var camera_controller: Node = null

# SubViewport'ы
var sub_viewport: SubViewport = null
var sub_viewport2: SubViewport = null
var tex_rect: TextureRect = null
var tex_rect2: TextureRect = null

var gate_code: int = 1337

func setup(
	ws: Node3D,
	robot_node: Node3D,
	cam_ctrl: Node,
	sv: SubViewport,
	sv2: SubViewport,
	tr: TextureRect,
	tr2: TextureRect
) -> void:
	world_scene = ws
	robot = robot_node
	camera_controller = cam_ctrl
	sub_viewport = sv
	sub_viewport2 = sv2
	tex_rect = tr
	tex_rect2 = tr2

	# Подключаемся к сигналам робота
	if robot and robot.has_signal("charging_zone_reached"):
		robot.charging_zone_reached.connect(_on_robot_charging)
	if robot and robot.has_signal("robot_camera_discovered"):
		robot.robot_camera_discovered.connect(_on_camera_discovered)

func handle_command(cmd: String, current_mode: String) -> String:
	match current_mode:
		"connect":
			return _handle_connect(cmd)
		"action_menu":
			return _handle_action_menu(cmd)
		"device":
			return _handle_device(cmd)
		"camera_menu":
			return _handle_camera_menu(cmd)
		"open_confirm":
			return _handle_open_confirm(cmd)
		"code":
			return _handle_code(cmd)
		"camera":
			return _handle_camera(cmd)
		"robot_direct":
			return _handle_robot_direct(cmd)
		"paused":
			return _handle_paused(cmd)
	return ""

func get_initial_mode() -> String:
	return "connect"

# === ПОДКЛЮЧЕНИЕ ===

func _handle_connect(cmd: String) -> String:
	if cmd == "Y":
		log_message.emit("УСТАНАВЛИВАЮ СОЕДИНЕНИЕ...")
		input_mode_changed.emit("")
		return "connecting"
	elif cmd == "N":
		log_message.emit("СОЕДИНЕНИЕ ОТКЛОНЕНО. ЗАВЕРШЕНИЕ...")
		get_tree().quit()
		return ""
	else:
		log_message.emit("НЕВЕРНАЯ КОМАНДА. ВВЕДИТЕ Y ИЛИ N.")
		return "connect"

func after_connect_delay() -> String:
	log_message.emit("СОЕДИНЕНИЕ УСТАНОВЛЕНО.")
	log_message.emit("ВИДЕОПОТОК С КАМЕРЫ НАБЛЮДЕНИЯ ПОЛУЧЕН.")
	log_message.emit("")
	log_message.emit("ВВЕДИТЕ 1 ДЛЯ МЕНЮ ДЕЙСТВИЙ.")
	hide_signal_screen.emit()
	show_camera_feed.emit()
	input_mode_changed.emit("action_menu")
	request_focus.emit()
	return "action_menu"

# === МЕНЮ ДЕЙСТВИЙ ===

func _handle_action_menu(cmd: String) -> String:
	match cmd:
		"1":
			log_message.emit("СКАНИРОВАНИЕ УСТРОЙСТВ...")
			devices_scanned = true
			log_message.emit("СКАНИРОВАНИЕ ЗАВЕРШЕНО.")
			log_message.emit("ОБНАРУЖЕНЫ УСТРОЙСТВА:")
			log_message.emit("  - ВОРОТА (ДВЕРЬ 1)")
			if gate_opened:
				log_message.emit("  - РОБОТ-РАЗВЕДЧИК")
				if robot_camera_discovered:
					log_message.emit("  - КАМЕРА РОБОТА")
			log_message.emit("")
			log_message.emit("ВВЕДИТЕ 2 ДЛЯ ПОДКЛЮЧЕНИЯ К УСТРОЙСТВУ.")
			return "action_menu"
		"2":
			log_message.emit("ДОСТУПНЫЕ УСТРОЙСТВА:")
			if devices_scanned:
				log_message.emit("  1 - ВОРОТА (ДВЕРЬ 1)")
				if gate_opened:
					log_message.emit("  2 - РОБОТ-РАЗВЕДЧИК")
			log_message.emit("  0 - НАЗАД")
			log_message.emit("")
			log_message.emit("ВВЕДИТЕ НОМЕР УСТРОЙСТВА:")
			input_mode_changed.emit("device")
			return "device"
		"3":
			log_message.emit("ДОСТУПНЫЕ КАМЕРЫ:")
			log_message.emit("  1 - КАМЕРА 1")
			if gate_opened:
				log_message.emit("  2 - КАМЕРА 2")
			if robot_camera_discovered:
				log_message.emit("  3 - КАМЕРА РОБОТА")
			if gate_opened:
				log_message.emit("  4 - РЕЖИМ ДВУХ КАМЕР")
			log_message.emit("  0 - НАЗАД")
			log_message.emit("")
			log_message.emit("ВЫБЕРИТЕ КАМЕРУ:")
			input_mode_changed.emit("camera_menu")
			return "camera_menu"
		_:
			log_message.emit("НЕВЕРНЫЙ ВЫБОР. ВВЕДИТЕ 1, 2 ИЛИ 3.")
			return "action_menu"
	return "action_menu"

# === УСТРОЙСТВА ===

func _handle_device(cmd: String) -> String:
	if cmd == "0":
		log_message.emit("ВОЗВРАТ В МЕНЮ ДЕЙСТВИЙ.")
		input_mode_changed.emit("action_menu")
		return "action_menu"
	if not cmd.is_valid_int():
		log_message.emit("ВВЕДИТЕ ЧИСЛО.")
		return "device"
	var num: int = int(cmd)
	match num:
		1:
			if not devices_scanned:
				log_message.emit("УСТРОЙСТВО НЕ ОБНАРУЖЕНО. СНАЧАЛА ПРОСКАНИРУЙТЕ СИСТЕМУ.")
				return "device"
			selected_device = 1
			log_message.emit("ПОДКЛЮЧЕНИЕ К ВОРОТАМ...")
			return "open_confirm_pending"
		2:
			if not gate_opened:
				log_message.emit("РОБОТ НЕДОСТУПЕН. СНАЧАЛА ОТКРОЙТЕ ВОРОТА.")
				return "device"
			if robot:
				robot.set_active(true)
			log_message.emit("ПОДКЛЮЧЕНИЕ К РОБОТУ-РАЗВЕДЧИКУ...")
			return "robot_pending"
		_:
			log_message.emit("НЕВЕРНЫЙ НОМЕР УСТРОЙСТВА. ВВЕДИТЕ 0-2.")
			return "device"
	return "device"

func after_device_pending(mode: String) -> String:
	if mode == "open_confirm_pending":
		log_message.emit("СОЕДИНЕНИЕ УСТАНОВЛЕНО. ОТКРЫТЬ ВОРОТА? (Y/N)")
		log_message.emit("ВВЕДИТЕ 0 ДЛЯ ОТМЕНЫ.")
		input_mode_changed.emit("open_confirm")
		return "open_confirm"
	elif mode == "robot_pending":
		log_message.emit("РОБОТ АКТИВИРОВАН.")
		log_message.emit("")
		log_message.emit("УПРАВЛЕНИЕ РОБОТОМ:")
		log_message.emit("  W / S - ВПЕРЁД / НАЗАД")
		log_message.emit("  A / D - ПОВОРОТ ВЛЕВО / ВПРАВО")
		log_message.emit("  0 - ОТКЛЮЧИТЬСЯ")
		log_message.emit("  ESC - ПАУЗА")
		log_message.emit("")
		input_mode_changed.emit("robot_direct")
		release_focus.emit()
		return "robot_direct"
	return "action_menu"

# === ОТКРЫТИЕ ВОРОТ ===

func _handle_open_confirm(cmd: String) -> String:
	if cmd == "0":
		log_message.emit("ОТМЕНА.")
		input_mode_changed.emit("action_menu")
		return "action_menu"
	if cmd == "Y":
		log_message.emit("ТРЕБУЕТСЯ КОД ДОСТУПА.")
		log_message.emit("ВВЕДИТЕ КОД (или 0 для отмены):")
		input_mode_changed.emit("code")
		return "code"
	elif cmd == "N":
		log_message.emit("ОТМЕНА.")
		input_mode_changed.emit("action_menu")
		return "action_menu"
	else:
		log_message.emit("ВВЕДИТЕ Y, N ИЛИ 0.")
		return "open_confirm"

func _handle_code(cmd: String) -> String:
	if cmd == "0":
		log_message.emit("ОТМЕНА ВВОДА КОДА.")
		input_mode_changed.emit("action_menu")
		return "action_menu"
	if not cmd.is_valid_int():
		log_message.emit("КОД ДОЛЖЕН СОСТОЯТЬ ТОЛЬКО ИЗ ЦИФР.")
		return "code"
	var code: int = int(cmd)
	if code == gate_code:
		log_message.emit("КОД ПРИНЯТ. ОТКРЫВАЮ ВОРОТА...")
		_open_gate_direct()
		log_message.emit("ВОРОТА ОТКРЫТЫ.")
		gate_opened = true
		input_mode_changed.emit("action_menu")
		return "action_menu"
	else:
		log_message.emit("НЕВЕРНЫЙ КОД. ПОПРОБУЙТЕ СНОВА.")
		log_message.emit("ВВЕДИТЕ 0 ДЛЯ ОТМЕНЫ.")
		return "code"

func _open_gate_direct() -> void:
	_find_and_open_gates(world_scene)
	if world_scene2:
		_find_and_open_gates(world_scene2)

func _find_and_open_gates(root: Node) -> void:
	if root.has_method("open_gate"):
		root.open_gate()
	for child in root.get_children():
		_find_and_open_gates(child)

# === КАМЕРЫ ===

func _handle_camera_menu(cmd: String) -> String:
	if cmd == "0":
		log_message.emit("ВОЗВРАТ В МЕНЮ ДЕЙСТВИЙ.")
		input_mode_changed.emit("action_menu")
		return "action_menu"
	if not cmd.is_valid_int():
		log_message.emit("ВВЕДИТЕ ЧИСЛО.")
		return "camera_menu"
	var num: int = int(cmd)
	match num:
		1:
			if dual_mode:
				_toggle_dual_mode()
			camera_controller.set_active_camera(1)
			selected_device = 2
			camera_controller.reset_zoom()
			log_message.emit("ПОДКЛЮЧЕНИЕ К КАМЕРЕ 1...")
			return "camera_pending_1"
		2:
			if not gate_opened:
				log_message.emit("КАМЕРА 2 НЕДОСТУПНА. СНАЧАЛА ОТКРОЙТЕ ВОРОТА.")
				return "camera_menu"
			if dual_mode:
				_toggle_dual_mode()
			camera_controller.set_active_camera(2)
			selected_device = 3
			camera_controller.reset_zoom()
			log_message.emit("ПОДКЛЮЧЕНИЕ К КАМЕРЕ 2...")
			return "camera_pending_2"
		3:
			if not robot_camera_discovered:
				log_message.emit("КАМЕРА РОБОТА НЕДОСТУПНА. ПОДОЙДИТЕ К ЗОНЕ ЗАРЯДКИ.")
				return "camera_menu"
			if dual_mode:
				_toggle_dual_mode()
			var robot_cam: Camera3D = robot.get_robot_camera()
			if robot_cam:
				robot_cam.current = true
				if camera_controller.world_camera:
					camera_controller.world_camera.current = false
				if camera_controller.camera2:
					camera_controller.camera2.current = false
			selected_device = 4
			camera_controller.reset_zoom()
			log_message.emit("ПОДКЛЮЧЕНИЕ К КАМЕРЕ РОБОТА...")
			log_message.emit("КАМЕРА РОБОТА АКТИВИРОВАНА.")
			log_message.emit("")
			log_message.emit("УПРАВЛЕНИЕ КАМЕРОЙ РОБОТА:")
			log_message.emit("  R<число> - ПОВЕРНУТЬ (например R15 или R-15)")
			log_message.emit("  S<число> - ПРИБЛИЗИТЬ (например S0.5)")
			log_message.emit("  0 - ВЫЙТИ")
			log_message.emit("")
			log_message.emit("ВВЕДИТЕ КОМАНДУ:")
			input_mode_changed.emit("camera")
			return "camera"
		4:
			if not gate_opened:
				log_message.emit("РЕЖИМ ДВУХ КАМЕР НЕДОСТУПЕН. СНАЧАЛА ОТКРОЙТЕ ВОРОТА.")
				return "camera_menu"
			_toggle_dual_mode()
			camera_controller.reset_zoom()
			log_message.emit("")
			log_message.emit("УПРАВЛЕНИЕ КАМЕРАМИ (DUAL MODE):")
			log_message.emit("  R<число> - ПОВЕРНУТЬ ОБЕ КАМЕРЫ")
			log_message.emit("  S<число> - ПРИБЛИЗИТЬ ОБЕ КАМЕРЫ")
			log_message.emit("  0 - ВЫЙТИ")
			log_message.emit("")
			log_message.emit("ВВЕДИТЕ КОМАНДУ:")
			input_mode_changed.emit("camera")
			return "camera"
		_:
			log_message.emit("НЕВЕРНЫЙ НОМЕР. ВВЕДИТЕ 0-4.")
			return "camera_menu"
	return "camera_menu"

func after_camera_pending(num: int) -> String:
	if num == 1:
		log_message.emit("КАМЕРА 1 АКТИВИРОВАНА.")
		log_message.emit("")
		log_message.emit("УПРАВЛЕНИЕ КАМЕРОЙ:")
		log_message.emit("  R<число> - ПОВЕРНУТЬ (например R15 или R-15)")
		log_message.emit("  S<число> - ПРИБЛИЗИТЬ (например S0.5)")
		log_message.emit("  0 - ВЫЙТИ")
		log_message.emit("")
		log_message.emit("ВВЕДИТЕ КОМАНДУ:")
		input_mode_changed.emit("camera")
	elif num == 2:
		log_message.emit("КАМЕРА 2 АКТИВИРОВАНА.")
		log_message.emit("")
		log_message.emit("УПРАВЛЕНИЕ КАМЕРОЙ 2:")
		log_message.emit("  R<число> - ПОВЕРНУТЬ (например R15 или R-15)")
		log_message.emit("  S<число> - ПРИБЛИЗИТЬ (например S0.5)")
		log_message.emit("  0 - ВЫЙТИ")
		log_message.emit("")
		log_message.emit("ВВЕДИТЕ КОМАНДУ:")
		input_mode_changed.emit("camera")
	return "camera"

func _handle_camera(cmd: String) -> String:
	if cmd == "0":
		if dual_mode:
			_toggle_dual_mode()
		log_message.emit("ВЫХОД ИЗ РЕЖИМА КАМЕРЫ.")
		input_mode_changed.emit("action_menu")
		return "action_menu"

	if dual_mode:
		if cmd.begins_with("R"):
			var angle_str: String = cmd.substr(1)
			if angle_str.is_valid_float():
				var angle: float = float(angle_str)
				camera_controller.rotate_camera(camera_controller.world_camera, angle)
				camera_controller.rotate_camera(camera_controller.camera2_copy, angle)
				log_message.emit("ОБЕ КАМЕРЫ ПОВОРАЧИВАЮТСЯ НА " + str(angle) + " ГРАДУСОВ.")
			else:
				log_message.emit("НЕВЕРНЫЙ ФОРМАТ. ИСПОЛЬЗУЙТЕ R<число>.")
		elif cmd.begins_with("S"):
			var zoom_str: String = cmd.substr(1)
			if zoom_str.is_valid_float():
				var zoom_change: float = float(zoom_str)
				camera_controller.zoom_camera(camera_controller.world_camera, zoom_change)
				camera_controller.zoom_camera(camera_controller.camera2_copy, zoom_change)
				log_message.emit("ОБЕ КАМЕРЫ: ПРИБЛИЖЕНИЕ x" + str(snapped(camera_controller.get_zoom_level(), 0.1)) + " (макс. 2x)")
			else:
				log_message.emit("НЕВЕРНЫЙ ФОРМАТ. ИСПОЛЬЗУЙТЕ S<число>.")
		else:
			log_message.emit("НЕИЗВЕСТНАЯ КОМАНДА. ИСПОЛЬЗУЙТЕ R<угол> или S<зум>.")
	else:
		var active_cam: Camera3D
		if selected_device == 4:
			active_cam = robot.get_robot_camera()
		elif selected_device == 3:
			active_cam = camera_controller.camera2
		else:
			active_cam = camera_controller.world_camera

		if cmd.begins_with("R"):
			var angle_str: String = cmd.substr(1)
			if angle_str.is_valid_float():
				var angle: float = float(angle_str)
				camera_controller.rotate_camera(active_cam, angle)
				log_message.emit("КАМЕРА ПЛАВНО ПОВОРАЧИВАЕТСЯ НА " + str(angle) + " ГРАДУСОВ.")
			else:
				log_message.emit("НЕВЕРНЫЙ ФОРМАТ. ИСПОЛЬЗУЙТЕ R<число>.")
		elif cmd.begins_with("S"):
			var zoom_str: String = cmd.substr(1)
			if zoom_str.is_valid_float():
				var zoom_change: float = float(zoom_str)
				camera_controller.zoom_camera(active_cam, zoom_change)
				log_message.emit("ПЛАВНОЕ ПРИБЛИЖЕНИЕ: x" + str(snapped(camera_controller.get_zoom_level(), 0.1)) + " (макс. 2x)")
			else:
				log_message.emit("НЕВЕРНЫЙ ФОРМАТ. ИСПОЛЬЗУЙТЕ S<число>.")
		else:
			log_message.emit("НЕИЗВЕСТНАЯ КОМАНДА. ИСПОЛЬЗУЙТЕ R<угол> или S<зум>.")

	return "camera"

# === РОБОТ ===

func _handle_robot_direct(cmd: String) -> String:
	if cmd == "0":
		if robot:
			robot.set_active(false)
		log_message.emit("ОТКЛЮЧЕНИЕ ОТ РОБОТА.")
		input_mode_changed.emit("action_menu")
		request_focus.emit()
		return "action_menu"
	else:
		log_message.emit("В РЕЖИМЕ УПРАВЛЕНИЯ ИСПОЛЬЗУЙТЕ WASD. ДЛЯ ВЫХОДА ВВЕДИТЕ 0.")
		return "robot_direct"

# === ПАУЗА ===

func handle_escape(current_mode: String) -> String:
	if current_mode == "paused":
		input_mode_changed.emit(previous_input_mode)
		log_message.emit("ПАУЗА СНЯТА.")
		request_focus.emit()
		return previous_input_mode
	else:
		previous_input_mode = current_mode
		input_mode_changed.emit("paused")
		log_message.emit("")
		log_message.emit("=== ПАУЗА ===")
		log_message.emit("Нажмите ESC чтобы продолжить")
		log_message.emit("")
		return "paused"

func _handle_paused(cmd: String) -> String:
	return "paused"

# === DUAL MODE ===

func _toggle_dual_mode() -> void:
	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	var W: float = viewport_rect.size.x
	var H: float = viewport_rect.size.y
	var third: float = W / 3.0
	var right_width: float = W - third

	if not dual_mode:
		var world_packed: PackedScene = load("res://scenes/world.tscn")
		world_scene2 = world_packed.instantiate()
		world_scene2.name = "WorldInstance2"
		sub_viewport2.add_child(world_scene2)

		camera_controller.camera2_copy = world_scene2.get_node_or_null("Camera2")

		if camera_controller.world_camera:
			camera_controller.world_camera.current = true
		if camera_controller.camera2:
			camera_controller.camera2.current = false
		if camera_controller.camera2_copy:
			camera_controller.camera2_copy.current = true

		_find_and_open_gates(world_scene2)

		sub_viewport.size = Vector2i(int(right_width), int(H / 2))
		tex_rect.size = Vector2(right_width, H / 2)
		tex_rect.position = Vector2(third, 0)

		sub_viewport2.size = Vector2i(int(right_width), int(H / 2))
		sub_viewport2.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		tex_rect2.size = Vector2(right_width, H / 2)
		tex_rect2.position = Vector2(third, H / 2)
		tex_rect2.visible = true

		dual_mode = true
		log_message.emit("РЕЖИМ ДВУХ КАМЕР АКТИВИРОВАН.")
		log_message.emit("  СВЕРХУ: КАМЕРА 1")
		log_message.emit("  СНИЗУ: КАМЕРА 2")
	else:
		if world_scene2:
			world_scene2.queue_free()
			world_scene2 = null
		camera_controller.camera2_copy = null

		sub_viewport.size = Vector2i(int(right_width), int(H))
		tex_rect.size = Vector2(right_width, H)
		tex_rect.position = Vector2(third, 0)

		sub_viewport2.render_target_update_mode = SubViewport.UPDATE_DISABLED
		tex_rect2.visible = false

		if camera_controller.world_camera:
			camera_controller.world_camera.current = true
		if camera_controller.camera2:
			camera_controller.camera2.current = false

		dual_mode = false
		log_message.emit("РЕЖИМ ОДНОЙ КАМЕРЫ АКТИВИРОВАН.")

# === СИГНАЛЫ РОБОТА ===

func _on_robot_charging(is_charging: bool) -> void:
	if is_charging:
		log_message.emit("РОБОТ НА ЗОНЕ ЗАРЯДКИ.")
		log_message.emit("ИНИЦИАЛИЗАЦИЯ СИСТЕМ...")

func _on_camera_discovered() -> void:
	robot_camera_discovered = true
	log_message.emit("ОБНАРУЖЕНА КАМЕРА НА РОБОТЕ.")
	log_message.emit("КАМЕРА ДОБАВЛЕНА В СПИСОК К ПОДКЛЮЧЕНИЮ.")
