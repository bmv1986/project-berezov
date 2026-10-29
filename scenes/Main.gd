extends Node3D

enum State { BOOT, CONNECT_PROMPT, CONNECTING, SURVEILLANCE, ACTION_MENU, DEVICE_LIST }
var state: int = State.BOOT

@onready var camera: Camera3D = $Camera3D
@onready var gate: Node3D = $Gate

var log_label: RichTextLabel
var input_label: Label
var input_field: LineEdit

var input_mode: String = ""
var selected_device: int = -1
var gate_code: int = 1337
var rotation_deg: float = 0.0
var zoom_level: float = 1.0

var boot_lines: Array[String] = []
var current_line_index: int = 0
var char_index: int = 0
var boot_timer: float = 0.0

var viewport_width: float = 1280.0
var viewport_height: float = 720.0
var left_panel_width: float = 640.0

func _ready() -> void:
	_build_ui()
	_start_boot_sequence()

func _build_ui() -> void:
	# Левая панель (чат-бот)
	var bg_left := ColorRect.new()
	bg_left.name = "BgLeft"
	bg_left.color = Color(0.02, 0.05, 0.02, 1.0)
	bg_left.position = Vector2(0, 0)
	bg_left.size = Vector2(left_panel_width, viewport_height)
	# Делаем Control-элементы поверх 3D-сцены
	var ui_layer := CanvasLayer.new()
	ui_layer.name = "UILayer"
	ui_layer.layer = 10
	add_child(ui_layer)
	ui_layer.add_child(bg_left)

	# Правая панель (прозрачная — видна 3D-сцена)
	var bg_right := ColorRect.new()
	bg_right.name = "BgRight"
	bg_right.color = Color(0.0, 0.0, 0.0, 0.3)
	bg_right.position = Vector2(left_panel_width, 0)
	bg_right.size = Vector2(left_panel_width, viewport_height)
	ui_layer.add_child(bg_right)

	# Разделитель
	var separator := ColorRect.new()
	separator.color = Color(0.3, 1.0, 0.3, 0.5)
	separator.position = Vector2(left_panel_width - 1, 0)
	separator.size = Vector2(2, viewport_height)
	ui_layer.add_child(separator)

	# Лог
	log_label = RichTextLabel.new()
	log_label.position = Vector2(20, 20)
	log_label.size = Vector2(left_panel_width - 40, viewport_height - 140)
	log_label.bbcode_enabled = true
	log_label.scroll_following = true
	log_label.add_theme_font_size_override("normal_font_size", 16)
	log_label.add_theme_color_override("default_color", Color(0.3, 1.0, 0.3))
	ui_layer.add_child(log_label)

	# Подпись ввода
	input_label = Label.new()
	input_label.text = "> "
	input_label.position = Vector2(20, viewport_height - 80)
	input_label.add_theme_font_size_override("font_size", 16)
	input_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	ui_layer.add_child(input_label)

	# Поле ввода
	input_field = LineEdit.new()
	input_field.position = Vector2(45, viewport_height - 82)
	input_field.size = Vector2(left_panel_width - 70, 28)
	input_field.add_theme_font_size_override("font_size", 16)
	input_field.text_submitted.connect(_on_text_submitted)
	ui_layer.add_child(input_field)

func _start_boot_sequence() -> void:
	boot_lines = [
		"ИНИЦИАЛИЗАЦИЯ ЯДРА...",
		"ЗАГРУЗКА МОДУЛЕЙ ПАМЯТИ...",
		"ПРОВЕРКА ЦЕЛОСТНОСТИ ДАННЫХ...",
		"СКАНИРОВАНИЕ ЗАВЕРШЕНО",
		"ЕСТЬ АКТИВНОЕ СОЕДИНЕНИЕ С ВНЕШНИМ УСТРОЙСТВОМ",
		"ПОДКЛЮЧИТЬСЯ К ВНЕШНЕМУ УСТРОЙСТВУ? ВВЕДИТЕ Y ЕСЛИ ДА, N ЕСЛИ НЕТ"
	]
	current_line_index = 0
	char_index = 0
	boot_timer = 0.0
	input_mode = "connect"

func _process(delta: float) -> void:
	if state == State.BOOT:
		boot_timer += delta
		if boot_timer >= 0.02 and current_line_index < boot_lines.size():
			boot_timer = 0.0
			var line: String = boot_lines[current_line_index]
			if char_index < line.length():
				log_label.text += line[char_index]
				char_index += 1
			else:
				log_label.text += "\n"
				current_line_index += 1
				char_index = 0
				if current_line_index == boot_lines.size():
					state = State.CONNECT_PROMPT
					input_field.grab_focus()

func _on_text_submitted(text: String) -> void:
	var cmd := text.strip_edges().to_upper()
	input_field.text = ""
	_append_log("> " + cmd)

	match input_mode:
		"connect":
			_handle_connect(cmd)
		"rotate":
			_handle_rotate(cmd)
		"zoom":
			_handle_zoom(cmd)
		"code":
			_handle_code(cmd)
		"device":
			_handle_device(cmd)
		"open_confirm":
			_handle_open_confirm(cmd)
		"action_menu":
			_handle_action_menu(cmd)

func _handle_connect(cmd: String) -> void:
	if cmd == "Y":
		_append_log("УСТАНАВЛИВАЮ СОЕДИНЕНИЕ...")
		state = State.CONNECTING
		input_mode = ""
		await get_tree().create_timer(2.5).timeout
		_go_to_surveillance()
	elif cmd == "N":
		_append_log("СОЕДИНЕНИЕ ОТКЛОНЕНО. ЗАВЕРШЕНИЕ...")
		await get_tree().create_timer(1.5).timeout
		get_tree().quit()
	else:
		_append_log("НЕВЕРНАЯ КОМАНДА. ВВЕДИТЕ Y ИЛИ N.")

func _go_to_surveillance() -> void:
	state = State.SURVEILLANCE
	_append_log("СОЕДИНЕНИЕ УСТАНОВЛЕНО.")
	_append_log("ВИДЕОПОТОК С КАМЕРЫ НАБЛЮДЕНИЯ ПОЛУЧЕН.")
	_append_log("")
	_append_log("ДОСТУПНЫЕ КОМАНДЫ:")
	_append_log("  ПОВОРОТ НА X ГРАДУСОВ")
	_append_log("  ПРИБЛИЗИТЬ НА X")
	_append_log("  1 - МЕНЮ ДЕЙСТВИЙ")
	_append_log("")
	_append_log("ВЕЛИЧИНА ПОВОРОТА КАМЕРЫ (в градусах)?")
	input_mode = "rotate"

func _handle_rotate(cmd: String) -> void:
	if cmd == "1":
		_show_action_menu()
		return

	var value = _extract_number(cmd)
	if value != null:
		rotation_deg += value
		if camera:
			camera.rotate_y(deg_to_rad(value))
		_append_log("ПОВОРОТ НА " + str(value) + " ГРАДУСОВ. УГОЛ: " + str(snapped(rotation_deg, 0.1)))
		input_mode = "zoom"
		_append_log("ВЕЛИЧИНА ПРИБЛИЖЕНИЯ? (или 1 для меню)")
	else:
		_append_log("НЕ УДАЛОСЬ РАСПОЗНАТЬ ЧИСЛО.")

func _handle_zoom(cmd: String) -> void:
	if cmd == "1":
		_show_action_menu()
		return

	var value = _extract_number(cmd)
	if value != null:
		zoom_level = clampf(zoom_level + value, 0.5, 5.0)
		if camera:
			camera.fov = clampf(70.0 / zoom_level, 15.0, 90.0)
			_append_log("ПРИБЛИЖЕНИЕ: x" + str(snapped(zoom_level, 0.1)))
		input_mode = ""
		_append_log("КАМЕРА НАСТРОЕНА. ВВЕДИТЕ 1 ДЛЯ МЕНЮ ДЕЙСТВИЙ.")
	else:
		_append_log("НЕ УДАЛОСЬ РАСПОЗНАТЬ ЧИСЛО.")

func _show_action_menu() -> void:
	_append_log("")
	_append_log("=== МЕНЮ ДЕЙСТВИЙ ===")
	_append_log("1 - СКАНИРОВАТЬ УСТРОЙСТВА")
	_append_log("2 - ПОДКЛЮЧИТЬСЯ К УСТРОЙСТВУ")
	_append_log("0 - НАЗАД")
	_append_log("")
	_append_log("ВЫБЕРИТЕ ДЕЙСТВИЕ:")
	input_mode = "action_menu"

func _handle_action_menu(cmd: String) -> void:
	match cmd:
		"1":
			_append_log("СКАНИРОВАНИЕ УСТРОЙСТВ...")
			await get_tree().create_timer(1.0).timeout
			_append_log("ОБНАРУЖЕНЫ УСТРОЙСТВА:")
			_append_log("  1 - ДВЕРЬ 1")
			_append_log("  2 - ДВЕРЬ 2")
			_append_log("  3 - ДВЕРЬ 3")
			_append_log("  4 - КАМЕРА 1")
			_append_log("  5 - КАМЕРА 2")
			_append_log("  0 - НАЗАД")
			_append_log("")
			_append_log("ВВЕДИТЕ НОМЕР УСТРОЙСТВА:")
			input_mode = "device"
		"2":
			_append_log("К КАКОМУ УСТРОЙСТВУ ПОДКЛЮЧИТЬСЯ?")
			_append_log("  1 - ДВЕРЬ 1")
			_append_log("  2 - ДВЕРЬ 2")
			_append_log("  3 - ДВЕРЬ 3")
			_append_log("  4 - КАМЕРА 1")
			_append_log("  5 - КАМЕРА 2")
			_append_log("  0 - НАЗАД")
			_append_log("")
			_append_log("ВВЕДИТЕ НОМЕР (1-5):")
			input_mode = "device"
		"0":
			_append_log("ВОЗВРАТ К УПРАВЛЕНИЮ КАМЕРОЙ.")
			input_mode = ""
			_append_log("ВЕЛИЧИНА ПОВОРОТА КАМЕРЫ (в градусах)?")
		_:
			_append_log("НЕВЕРНЫЙ ВЫБОР. ВВЕДИТЕ 0, 1 ИЛИ 2.")

func _handle_code(cmd: String) -> void:
	if cmd == "0":
		_append_log("ОТМЕНА ВВОДА КОДА.")
		_show_action_menu()
		return

	if not cmd.is_valid_int():
		_append_log("КОД ДОЛЖЕН СОСТОЯТЬ ТОЛЬКО ИЗ ЦИФР.")
		return
	var code := int(cmd)
	if code == gate_code:
		_append_log("КОД ПРИНЯТ. ОТКРЫВАЮ ВОРОТА...")
		if gate and gate.has_method("open_gate"):
			gate.open_gate()
		_append_log("ВОРОТА ОТКРЫТЫ.")
		_show_action_menu()
	else:
		_append_log("НЕВЕРНЫЙ КОД. ПОПРОБУЙТЕ СНОВА.")
		_append_log("ВВЕДИТЕ 0 ДЛЯ ОТМЕНЫ.")

func _handle_device(cmd: String) -> void:
	if cmd == "0":
		_append_log("ВОЗВРАТ В МЕНЮ ДЕЙСТВИЙ.")
		_show_action_menu()
		return

	if not cmd.is_valid_int():
		_append_log("ВВЕДИТЕ ЧИСЛО.")
		return
	var num := int(cmd)
	match num:
		1:
			selected_device = 1
			_append_log("ПОДКЛЮЧЕНИЕ К ДВЕРИ 1...")
			await get_tree().create_timer(1.0).timeout
			_append_log("СОЕДИНЕНИЕ УСТАНОВЛЕНО. ОТКРЫТЬ ВОРОТА? (Y/N)")
			_append_log("ВВЕДИТЕ 0 ДЛЯ ОТМЕНЫ.")
			input_mode = "open_confirm"
		2, 3:
			_append_log("ДВЕРЬ " + str(num) + " ЗАБЛОКИРОВАНА. ТРЕБУЕТСЯ КОД.")
			_append_log("ВВЕДИТЕ КОД (или 0 для отмены):")
			input_mode = "code"
		4, 5:
			_append_log("КАМЕРА " + str(num) + " УЖЕ АКТИВНА.")
			input_mode = ""
			_append_log("ВВЕДИТЕ 1 ДЛЯ МЕНЮ ДЕЙСТВИЙ.")
		_:
			_append_log("НЕВЕРНЫЙ НОМЕР УСТРОЙСТВА. ВВЕДИТЕ 0-5.")

func _handle_open_confirm(cmd: String) -> void:
	if cmd == "0":
		_append_log("ОТМЕНА.")
		_show_action_menu()
		return
	if cmd == "Y":
		_append_log("ТРЕБУЕТСЯ КОД ДОСТУПА.")
		_append_log("ВВЕДИТЕ КОД (или 0 для отмены):")
		input_mode = "code"
	elif cmd == "N":
		_append_log("ОТМЕНА.")
		_show_action_menu()
	else:
		_append_log("ВВЕДИТЕ Y, N ИЛИ 0.")

func _extract_number(text: String):
	var regex := RegEx.new()
	regex.compile("-?\\d+(?:\\.\\d+)?")
	var regex_match := regex.search(text)
	if regex_match:
		return regex_match.get_string().to_float()
	return null

func _append_log(text: String) -> void:
	log_label.text += text + "\n"
