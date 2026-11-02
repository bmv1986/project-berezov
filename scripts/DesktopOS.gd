extends Control

# Ссылки на объекты мира
var camera_controller: Node = null
var sub_viewport: SubViewport = null
var tex_rect: TextureRect = null
var robot: Node3D = null
var command_router: Node = null
var main_node: Control = null

# UI элементы
var scan_devices_btn: Button
var cameras_btn: Button
var archive_btn: Button
var network_btn: Button
var start_btn: Button
var clock_label: Label
var windows_container: Control
var current_window: Control = null

func setup(cc: Node, sv: SubViewport, tr: TextureRect, rb: Node3D, cr: Node, main: Control) -> void:
	camera_controller = cc
	sub_viewport = sv
	tex_rect = tr
	robot = rb
	command_router = cr
	main_node = main

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	# Фон
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.08, 0.15, 0.92)
	bg.set_anchors_preset(15)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Ярлыки слева
	var icons_container := VBoxContainer.new()
	icons_container.position = Vector2(20, 80)
	icons_container.size = Vector2(220, 400)
	# ИСПРАВЛЕНО: используем метод вместо прямого доступа к словарю
	icons_container.add_theme_constant_override("separation", 15) 
	add_child(icons_container)

	scan_devices_btn = _make_button("📡 Сканировать устройства")
	scan_devices_btn.pressed.connect(_on_scan_devices)
	icons_container.add_child(scan_devices_btn)

	cameras_btn = _make_button("📷 Камеры")
	cameras_btn.pressed.connect(_on_cameras)
	icons_container.add_child(cameras_btn)

	archive_btn = _make_button("📁 Архивные записи")
	archive_btn.pressed.connect(_on_archive)
	icons_container.add_child(archive_btn)

	network_btn = _make_button("🌐 Сеть")
	network_btn.pressed.connect(_on_network)
	icons_container.add_child(network_btn)

	# Панель задач
	var taskbar := Panel.new()
	taskbar.set_anchors_preset(15)
	taskbar.offset_top = -50
	add_child(taskbar)

	start_btn = Button.new()
	start_btn.text = "Пуск"
	start_btn.size = Vector2(80, 40)
	start_btn.position = Vector2(10, 5)
	start_btn.pressed.connect(_on_start_menu)
	taskbar.add_child(start_btn)

	clock_label = Label.new()
	clock_label.text = "00:00"
	clock_label.position = Vector2(1200, 12)
	clock_label.size = Vector2(100, 30)
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	taskbar.add_child(clock_label)

	# Контейнер для окон
	windows_container = Control.new()
	windows_container.set_anchors_preset(15)
	windows_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(windows_container)

	_update_clock()

func _make_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.size = Vector2(200, 50)
	btn.add_theme_font_size_override("font_size", 13)
	return btn

func _process(_delta: float) -> void:
	if Engine.get_frames_drawn() % 60 == 0:
		_update_clock()

func _update_clock() -> void:
	if not clock_label:
		return
	var time = Time.get_time_dict_from_system()
	var hours = str(time["hour"]).pad_zeros(2)
	var minutes = str(time["minute"]).pad_zeros(2)
	clock_label.text = "%s:%s" % [hours, minutes]

func _on_scan_devices() -> void:
	_open_scan_window()

func _on_cameras() -> void:
	_open_cameras_window()

func _on_archive() -> void:
	_open_window("Архивные записи",
		"Записи за последние 24 часа:\n\n" +
		"• 14:23 - Обнаружено движение в секторе 7\n" +
		"• 12:45 - Открытие ворот (код 1337)\n" +
		"• 09:12 - Подключение к роботу\n" +
		"• 08:30 - Инициализация системы")

func _on_network() -> void:
	_open_window("Сетевые подключения",
		"Статус сети:\n\n" +
		"✓ Внешнее соединение - АКТИВНО\n" +
		"✓ Камера наблюдения - ПОДКЛЮЧЕНА\n" +
		"✓ Робот - ПОДКЛЮЧЁН\n" +
		"✗ Ворота - ОТКЛЮЧЕНЫ\n\n" +
		"IP: 192.168.1.100\n" +
		"Ping: 12ms")

func _on_start_menu() -> void:
	var menu = PopupMenu.new()
	menu.add_item("Выход из системы")
	menu.add_item("Перезагрузка")
	menu.add_item("Завершение работы")
	menu.index_pressed.connect(func(idx):
		if idx == 0:
			get_tree().quit()
		elif idx == 1:
			get_tree().reload_current_scene()
		elif idx == 2:
			get_tree().quit()
	)
	add_child(menu)
	menu.popup(Rect2(Vector2(10, get_viewport_rect().size.y - 200), Vector2(200, 150)))

# === ОКНО СКАНИРОВАНИЯ ===

func _open_scan_window() -> void:
	if current_window:
		current_window.queue_free()
		current_window = null

	var window = Panel.new()
	window.size = Vector2(500, 400)
	window.position = Vector2(
		get_viewport_rect().size.x / 2 - 250,
		get_viewport_rect().size.y / 2 - 200
	)

	var title_bar = ColorRect.new()
	title_bar.size = Vector2(500, 30)
	title_bar.color = Color(0.1, 0.3, 0.5, 1.0)
	window.add_child(title_bar)

	var title_label = Label.new()
	title_label.text = "Сканирование устройств"
	title_label.position = Vector2(10, 5)
	title_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	title_label.add_theme_font_size_override("font_size", 14)
	title_bar.add_child(title_label)

	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.position = Vector2(470, 2)
	close_btn.size = Vector2(28, 26)
	close_btn.pressed.connect(func():
		window.queue_free()
		current_window = null
	)
	title_bar.add_child(close_btn)

	var devices_label = Label.new()
	devices_label.text = "Обнаруженные устройства:\n\n"
	devices_label.position = Vector2(10, 40)
	devices_label.size = Vector2(480, 200)
	devices_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	devices_label.add_theme_font_size_override("font_size", 13)
	window.add_child(devices_label)

	var connect_robot_btn = Button.new()
	connect_robot_btn.text = "🤖 Подключиться к роботу"
	connect_robot_btn.position = Vector2(10, 260)
	connect_robot_btn.size = Vector2(200, 40)
	connect_robot_btn.pressed.connect(func():
		if main_node and main_node.has_method("set_game_mode"):
			main_node.set_game_mode("robot")
		devices_label.text += "\n✓ Робот выбран! Нажмите TAB для перехода в режим управления."
		connect_robot_btn.disabled = true
	)
	window.add_child(connect_robot_btn)

	var connect_gate_btn = Button.new()
	connect_gate_btn.text = "🚪 Подключиться к воротам"
	connect_gate_btn.position = Vector2(220, 260)
	connect_gate_btn.size = Vector2(200, 40)
	connect_gate_btn.pressed.connect(func():
		if command_router:
			command_router.handle_command("Y", "open_confirm")
		devices_label.text += "\n✓ Запрос на открытие ворот отправлен!"
		connect_gate_btn.disabled = true
	)
	window.add_child(connect_gate_btn)

	windows_container.add_child(window)
	current_window = window

# === ОКНО КАМЕР ===

func _open_cameras_window() -> void:
	if current_window:
		current_window.queue_free()
		current_window = null

	var window = Panel.new()
	window.size = Vector2(500, 400)
	window.position = Vector2(
		get_viewport_rect().size.x / 2 - 250,
		get_viewport_rect().size.y / 2 - 200
	)

	var title_bar = ColorRect.new()
	title_bar.size = Vector2(500, 30)
	title_bar.color = Color(0.1, 0.3, 0.5, 1.0)
	window.add_child(title_bar)

	var title_label = Label.new()
	title_label.text = "Камеры наблюдения"
	title_label.position = Vector2(10, 5)
	title_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	title_label.add_theme_font_size_override("font_size", 14)
	title_bar.add_child(title_label)

	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.position = Vector2(470, 2)
	close_btn.size = Vector2(28, 26)
	close_btn.pressed.connect(func():
		window.queue_free()
		current_window = null
	)
	title_bar.add_child(close_btn)

	var cameras_label = Label.new()
	cameras_label.text = "Доступные камеры:\n\n"
	cameras_label.position = Vector2(10, 40)
	cameras_label.size = Vector2(480, 200)
	cameras_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cameras_label.add_theme_font_size_override("font_size", 13)
	window.add_child(cameras_label)

	var cam1_btn = Button.new()
	cam1_btn.text = "📷 Камера 1 (Наблюдение)"
	cam1_btn.position = Vector2(10, 260)
	cam1_btn.size = Vector2(220, 40)
	cam1_btn.pressed.connect(func():
		if main_node and main_node.has_method("set_game_mode"):
			main_node.set_game_mode("camera1")
		cameras_label.text += "\n✓ Камера 1 выбрана! Нажмите TAB."
	)
	window.add_child(cam1_btn)

	var cam2_btn = Button.new()
	cam2_btn.text = "📷 Камера 2"
	cam2_btn.position = Vector2(240, 260)
	cam2_btn.size = Vector2(220, 40)
	cam2_btn.pressed.connect(func():
		if main_node and main_node.has_method("set_game_mode"):
			main_node.set_game_mode("camera2")
		cameras_label.text += "\n✓ Камера 2 выбрана! Нажмите TAB."
	)
	window.add_child(cam2_btn)

	var robot_cam_btn = Button.new()
	robot_cam_btn.text = "🤖 Камера робота"
	robot_cam_btn.position = Vector2(10, 310)
	robot_cam_btn.size = Vector2(220, 40)
	robot_cam_btn.pressed.connect(func():
		if main_node and main_node.has_method("set_game_mode"):
			main_node.set_game_mode("robot")
		cameras_label.text += "\n✓ Камера робота выбрана! Нажмите TAB."
	)
	window.add_child(robot_cam_btn)

	windows_container.add_child(window)
	current_window = window

# === ОБЩЕЕ ОКНО ===

func _open_window(title: String, content: String) -> void:
	if current_window:
		current_window.queue_free()
		current_window = null

	var window = Panel.new()
	window.size = Vector2(500, 350)
	window.position = Vector2(
		get_viewport_rect().size.x / 2 - 250,
		get_viewport_rect().size.y / 2 - 175
	)

	var title_bar = ColorRect.new()
	title_bar.size = Vector2(500, 30)
	title_bar.color = Color(0.1, 0.3, 0.5, 1.0)
	window.add_child(title_bar)

	var title_label = Label.new()
	title_label.text = title
	title_label.position = Vector2(10, 5)
	title_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	title_label.add_theme_font_size_override("font_size", 14)
	title_bar.add_child(title_label)

	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.position = Vector2(470, 2)
	close_btn.size = Vector2(28, 26)
	close_btn.pressed.connect(func():
		window.queue_free()
		current_window = null
	)
	title_bar.add_child(close_btn)

	var content_label = Label.new()
	content_label.text = content
	content_label.position = Vector2(10, 40)
	content_label.size = Vector2(480, 300)
	content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_label.add_theme_font_size_override("font_size", 13)
	window.add_child(content_label)

	windows_container.add_child(window)
	current_window = window
