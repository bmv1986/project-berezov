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
var bg_right: ColorRect = null
var no_signal: Label = null

var current_mode: String = ""

func _ready() -> void:
	set_anchors_preset(15)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0

	camera_controller = Node.new()
	camera_controller.name = "CameraController"
	camera_controller.set_script(load("res://scripts/CameraController.gd"))
	add_child(camera_controller)

	command_router = Node.new()
	command_router.name = "CommandRouter"
	command_router.set_script(load("res://scripts/CommandRouter.gd"))
	add_child(command_router)

	# Сначала создаём UI элементы
	_build_ui()

	# Потом загружаем мир
	_load_world()

	# Связываем сигналы
	chat_bot.command_entered.connect(_on_command)
	command_router.log_message.connect(_on_log)
	command_router.input_mode_changed.connect(_on_mode_changed)
	command_router.request_focus.connect(_on_request_focus)
	command_router.release_focus.connect(_on_release_focus)
	command_router.hide_signal_screen.connect(_on_hide_signal)
	command_router.show_camera_feed.connect(_on_show_camera_feed)

	command_router.setup(
		world_scene, robot, camera_controller,
		sub_viewport, sub_viewport2, tex_rect, tex_rect2
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

func _build_ui() -> void:
	var W: float = get_viewport_rect().size.x
	var H: float = get_viewport_rect().size.y
	var third: float = W / 3.0

	# Левая панель (терминал)
	var bg_left := ColorRect.new()
	bg_left.color = Color(0.05, 0.05, 0.08, 1.0)
	bg_left.set_anchors_preset(15)
	bg_left.offset_right = third
	add_child(bg_left)

	# Правая панель (чёрная, скрывается)
	bg_right = ColorRect.new()
	bg_right.color = Color(0.0, 0.0, 0.0, 1.0)
	bg_right.set_anchors_preset(15)
	bg_right.offset_left = third
	add_child(bg_right)

	# "НЕТ СИГНАЛА"
	no_signal = Label.new()
	no_signal.text = "НЕТ СИГНАЛА"
	no_signal.set_anchors_preset(15)
	no_signal.offset_left = third + (W - third) / 2.0 - 100
	no_signal.offset_right = third + (W - third) / 2.0 + 100
	no_signal.offset_top = -20
	no_signal.offset_bottom = 20
	no_signal.add_theme_font_size_override("font_size", 28)
	no_signal.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1.0))
	add_child(no_signal)

	# Разделитель
	var separator := ColorRect.new()
	separator.color = Color(0.0, 0.0, 0.0, 0.5)
	separator.set_anchors_preset(15)
	separator.offset_left = third - 1
	separator.offset_right = third + 1
	add_child(separator)

	# ChatBot (просто создаём, но не добавляем в дерево пока)
	chat_bot = Control.new()
	chat_bot.name = "ChatBot"
	chat_bot.set_script(load("res://scripts/ChatBot.gd"))
	chat_bot.set_anchors_preset(15)
	chat_bot.offset_left = 0
	chat_bot.offset_top = 0
	chat_bot.offset_right = 0
	chat_bot.offset_bottom = 0
	add_child(chat_bot)

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
	tex_rect.visible = false  # Скрыт до подключения
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
	if bg_right:
		bg_right.visible = false
	if no_signal:
		no_signal.visible = false

func _on_show_camera_feed() -> void:
	tex_rect.visible = true

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		current_mode = command_router.handle_escape(current_mode)
