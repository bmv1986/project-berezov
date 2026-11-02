extends Control

var chat_bot: Control = null
var command_router: Node = null
var camera_controller: Node = null

var world_scene: Node3D = null
var robot: Node3D = null

var sub_viewport: SubViewport = null
var sub_viewport2: SubViewport = null
var tex_rect: TextureRect = null
var tex_rect2: TextureRect = null

var current_mode: String = ""

var os_update: Control = null
var desktop_os: Control = null
var os_mode: bool = false
var desktop_visible: bool = false
var selected_game_mode: String = ""

func _ready() -> void:
	set_anchors_preset(15)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0

	var cam_ctrl_script = load("res://scripts/CameraController.gd")
	camera_controller = Node.new()
	camera_controller.name = "CameraController"
	camera_controller.set_script(cam_ctrl_script)
	add_child(camera_controller)

	var cmd_router_script = load("res://scripts/CommandRouter.gd")
	command_router = Node.new()
	command_router.name = "CommandRouter"
	command_router.set_script(cmd_router_script)
	add_child(command_router)

	_load_world()

	var chat_script = load("res://scripts/ChatBot.gd")
	chat_bot = Control.new()
	chat_bot.name = "ChatBot"
	chat_bot.set_script(chat_script)
	add_child(chat_bot)
	chat_bot.set_anchors_preset(15)

	var os_script = load("res://scripts/OSUpdate.gd")
	os_update = Control.new()
	os_update.name = "OSUpdate"
	os_update.set_script(os_script)
	add_child(os_update)
	os_update.set_anchors_preset(15)
	os_update.visible = false
	os_update.update_finished.connect(_on_update_finished)

	var desktop_script = load("res://scripts/Desktop.gd")
	desktop_os = Control.new()
	desktop_os.name = "DesktopOS"
	desktop_os.set_script(desktop_script)
	add_child(desktop_os)
	desktop_os.set_anchors_preset(15)
	desktop_os.visible = false

	# Связываем сигналы
	chat_bot.command_entered.connect(_on_command)
	command_router.log_message.connect(_on_log)
	command_router.input_mode_changed.connect(_on_mode_changed)
	command_router.request_focus.connect(_on_request_focus)
	command_router.release_focus.connect(_on_release_focus)
	command_router.hide_signal_screen.connect(_on_hide_signal)
	command_router.show_camera_feed.connect(_on_show_camera_feed)

	if robot and robot.has_signal("charging_station_reached"):
		robot.charging_station_reached.connect(_on_charging_station)
	if robot and robot.has_signal("robot_deactivated"):
		robot.robot_deactivated.connect(_on_robot_deactivated)

	command_router.setup(
		world_scene, robot, camera_controller,
		sub_viewport, sub_viewport2, tex_rect, tex_rect2
	)

	if desktop_os.has_method("setup"):
		desktop_os.setup(
			camera_controller, sub_viewport, tex_rect,
			robot, command_router, self
		)

	var boot_lines: Array[String] = [
		"ИНИЦИАЛИЗАЦИЯ ЯДРА...",
		"ЗАГРУЗКА МОДУЛЕЙ ПАМЯТИ...",
		"ПРОВЕРКА ЦЕЛОСТНОСТИ ДАННЫХ...",
		"СКАНИРОВАНИЕ ЗАВЕРШЕНО",
		"ЕСТЬ АКТИВНОЕ СОЕДИНЕНИЕ С ВНЕШНИМ УСТРОЙСТВОМ",
		"ПОДКЛЮЧИТЬСЯ К ВНЕШНЕМУ УСТРОЙСТВУ? ВВЕДИТЕ Y ЕСЛИ ДА, N ЕСЛИ НЕТ"
	]
	chat_bot.start_boot_sequence(boot_lines)
	current_mode = command_router.get_initial_mode()

func _load_world() -> void:
	var W: float = get_viewport_rect().size.x
	var H: float = get_viewport_rect().size.y
	var third: float = W / 3.0
	var right_width: float = W - third

	sub_viewport = SubViewport.new()
	sub_viewport.name = "WorldViewport"
	sub_viewport.size = Vector2i(int(right_width), int(H))
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sub_viewport.transparent_bg = false

	var world_packed: PackedScene = load("res://scenes/world.tscn")
	world_scene = world_packed.instantiate()
	world_scene.name = "WorldInstance"
	sub_viewport.add_child(world_scene)

	tex_rect = TextureRect.new()
	tex_rect.name = "WorldFeed"
	tex_rect.texture = sub_viewport.get_texture()
	tex_rect.position = Vector2(third, 0)
	tex_rect.size = Vector2(right_width, H)
	tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
	tex_rect.visible = false
	add_child(sub_viewport)
	add_child(tex_rect)

	sub_viewport2 = SubViewport.new()
	sub_viewport2.name = "WorldViewport2"
	sub_viewport2.size = Vector2i(int(right_width), int(H / 2))
	sub_viewport2.render_target_update_mode = SubViewport.UPDATE_DISABLED
	sub_viewport2.transparent_bg = false

	tex_rect2 = TextureRect.new()
	tex_rect2.name = "WorldFeed2"
	tex_rect2.texture = sub_viewport2.get_texture()
	tex_rect2.position = Vector2(third, H / 2)
	tex_rect2.size = Vector2(right_width, H / 2)
	tex_rect2.stretch_mode = TextureRect.STRETCH_SCALE
	tex_rect2.visible = false
	add_child(sub_viewport2)
	add_child(tex_rect2)

	var cam1: Camera3D = world_scene.get_node_or_null("Camera3D")
	var cam2: Camera3D = world_scene.get_node_or_null("Camera2")
	camera_controller.setup(cam1, cam2)
	camera_controller.set_active_camera(1)

	robot = world_scene.get_node_or_null("bunker/Robot")

func _on_command(cmd: String) -> void:
	if os_mode:
		return
	if cmd == "__boot_finished__":
		current_mode = command_router.get_initial_mode()
		chat_bot.focus_input()
		return
	var new_mode: String = command_router.handle_command(cmd, current_mode)
	if new_mode == "connecting":
		current_mode = ""
		chat_bot.set_input_enabled(false)
		await get_tree().create_timer(2.5).timeout
		current_mode = command_router.after_connect_delay()
	elif new_mode == "open_confirm_pending" or new_mode == "robot_pending":
		current_mode = ""
		chat_bot.set_input_enabled(false)
		await get_tree().create_timer(1.0).timeout
		current_mode = command_router.after_device_pending(new_mode)
		chat_bot.set_input_enabled(true)
	elif new_mode == "camera_pending_1":
		current_mode = ""
		chat_bot.set_input_enabled(false)
		await get_tree().create_timer(1.0).timeout
		current_mode = command_router.after_camera_pending(1)
		chat_bot.set_input_enabled(true)
	elif new_mode == "camera_pending_2":
		current_mode = ""
		chat_bot.set_input_enabled(false)
		await get_tree().create_timer(1.0).timeout
		current_mode = command_router.after_camera_pending(2)
		chat_bot.set_input_enabled(true)
	elif new_mode != "":
		current_mode = new_mode

func _on_log(text: String) -> void:
	chat_bot.append_log(text)

func _on_mode_changed(mode: String) -> void:
	current_mode = mode

func _on_request_focus() -> void:
	chat_bot.set_input_enabled(true)
	chat_bot.focus_input()

func _on_release_focus() -> void:
	chat_bot.set_input_enabled(false)
	chat_bot.unfocus_input()

func _on_hide_signal() -> void:
	chat_bot.hide_signal_screen()

func _on_show_camera_feed() -> void:
	# В консольном режиме камера показывается только справа
	if not os_mode:
		var W: float = get_viewport_rect().size.x
		var H: float = get_viewport_rect().size.y
		var third: float = W / 3.0
		var right_width: float = W - third
		
		tex_rect.visible = true
		tex_rect.set_anchors_preset(0)
		tex_rect.offset_left = 0
		tex_rect.offset_top = 0
		tex_rect.offset_right = 0
		tex_rect.offset_bottom = 0
		tex_rect.position = Vector2(third, 0)
		tex_rect.size = Vector2(right_width, H)
		
		move_child(chat_bot, -1)
	else:
		_show_camera_fullscreen()
	
	if camera_controller.world_camera:
		camera_controller.world_camera.current = true
	if camera_controller.camera2:
		camera_controller.camera2.current = false
	
	await get_tree().process_frame
	tex_rect.texture = sub_viewport.get_texture()
	
	# Показываем подсказку о меню команд
	if chat_bot and not os_mode:
		chat_bot.set_input_enabled(true)
		chat_bot.focus_input()

func _on_robot_deactivated() -> void:
	chat_bot.append_log("РОБОТ ОТКЛЮЧЁН.")
	chat_bot.set_input_enabled(false)

func _on_charging_station() -> void:
	if not os_mode:
		os_mode = true
		chat_bot.append_log("")
		chat_bot.append_log("ПОДКЛЮЧЕНИЕ К ЗАРЯДНОЙ СТАНЦИИ...")
		chat_bot.append_log("УПРАВЛЕНИЕ РОБОТОМ ПРЕКРАЩЕНО.")
		await get_tree().create_timer(2.0).timeout
		chat_bot.append_log("")
		chat_bot.append_log("ОБНАРУЖЕНА НОВАЯ ВЕРСИЯ ОПЕРАЦИОННОЙ СИСТЕМЫ.")
		chat_bot.append_log("СИСТЕМА БУДЕТ УСТАНОВЛЕНА АВТОМАТИЧЕСКИ.")
		await get_tree().create_timer(3.0).timeout
		chat_bot.visible = false
		tex_rect.visible = false
		os_update.start_update()

func _on_update_finished() -> void:
	await get_tree().create_timer(1.5).timeout
	_show_desktop()

# === ПОКАЗАТЬ DESKTOP ===
func _show_desktop() -> void:
	# Скрываем камеру
	tex_rect.visible = false
	if sub_viewport:
		sub_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	
	# Показываем Desktop и перемещаем в самый конец (поверх всего)
	desktop_os.visible = true
	desktop_visible = true
	selected_game_mode = "none"
	move_child(desktop_os, -1)
	
	print(">>> Desktop OS активирован. Нажмите TAB чтобы перейти в игровой режим.")

# === СКРЫТЬ DESKTOP (переход в игру) ===
func _hide_desktop() -> void:
	desktop_os.visible = false
	desktop_visible = false
	_activate_game_mode()

# === ПЕРЕКЛЮЧЕНИЕ ПО TAB ===
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		current_mode = command_router.handle_escape(current_mode)
	
	if os_mode and Input.is_key_pressed(KEY_TAB):
		if not _tab_was_pressed:
			_tab_was_pressed = true
			if desktop_visible:
				_hide_desktop()
				print(">>> Desktop скрыт. Игровой режим: ", selected_game_mode)
			else:
				_show_desktop()
				print(">>> Desktop показан. Меню.")
	else:
		_tab_was_pressed = false

var _tab_was_pressed: bool = false

func _activate_game_mode() -> void:
	match selected_game_mode:
		"robot":
			if robot and robot.has_method("set_active"):
				robot.set_active(true)
			_connect_to_robot_camera_fullscreen()
		"camera1":
			_connect_to_camera_fullscreen(1)
		"camera2":
			_connect_to_camera_fullscreen(2)
		_:
			_show_camera_fullscreen()

func _connect_to_robot_camera_fullscreen() -> void:
	if robot and robot.has_method("get_robot_camera"):
		var robot_cam: Camera3D = robot.get_robot_camera()
		if robot_cam:
			if camera_controller and camera_controller.world_camera:
				camera_controller.world_camera.current = false
			if camera_controller and camera_controller.camera2:
				camera_controller.camera2.current = false
			robot_cam.current = true
	_show_camera_fullscreen()
	print(">>> Режим робота активирован")

func _connect_to_camera_fullscreen(cam_num: int) -> void:
	if camera_controller:
		camera_controller.set_active_camera(cam_num)
		if camera_controller.world_camera:
			camera_controller.world_camera.current = (cam_num == 1)
		if camera_controller.camera2:
			camera_controller.camera2.current = (cam_num == 2)
	_show_camera_fullscreen()
	print(">>> Камера ", cam_num, " активирована")

func _show_camera_fullscreen() -> void:
	if tex_rect:
		tex_rect.visible = true
		tex_rect.set_anchors_preset(15)
		tex_rect.offset_left = 0
		tex_rect.offset_top = 0
		tex_rect.offset_right = 0
		tex_rect.offset_bottom = 0
		tex_rect.get_parent().move_child(tex_rect, -1)
	if sub_viewport:
		sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

func set_game_mode(mode: String) -> void:
	selected_game_mode = mode
	print(">>> Выбран игровой режим: ", mode)
