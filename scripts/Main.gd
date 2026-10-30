extends Control

enum State { BOOT, CONNECT_PROMPT, CONNECTING, SURVEILLANCE, ACTION_MENU, DEVICE_LIST, CAMERA_CONTROL }
var state: int = State.BOOT

var log_label: RichTextLabel
var input_label: Label
var input_field: LineEdit

var input_mode: String = ""
var selected_device: int = -1
var gate_code: int = 1337
var rotation_deg: float = 0.0
var zoom_level: float = 1.0
var devices_scanned: bool = false
var gate_opened: bool = false
var dual_mode: bool = false

var boot_lines: Array[String] = []
var current_line_index: int = 0
var char_index: int = 0
var boot_timer: float = 0.0

var world_scene: Node3D = null
var world_scene2: Node3D = null
var world_camera: Camera3D = null
var camera2: Camera3D = null
var camera2_copy: Camera3D = null

var sub_viewport: SubViewport = null
var sub_viewport2: SubViewport = null
var tex_rect: TextureRect = null
var tex_rect2: TextureRect = null

func _ready() -> void:
	_build_ui()
	_start_boot_sequence()

func _build_ui() -> void:
	var W := get_viewport_rect().size.x
	var H := get_viewport_rect().size.y
	var third := W / 3.0

	var bg_left := ColorRect.new()
	bg_left.color = Color(0.05, 0.05, 0.08, 1.0)
	bg_left.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_left.offset_right = third
	add_child(bg_left)

	var bg_right := ColorRect.new()
	bg_right.name = "BgRight"
	bg_right.color = Color(0.0, 0.0, 0.0, 1.0)
	bg_right.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_right.offset_left = third
	add_child(bg_right)

	var no_signal := Label.new()
	no_signal.name = "NoSignal"
	no_signal.text = "НЕТ СИГНАЛА"
	no_signal.set_anchors_preset(Control.PRESET_CENTER)
	no_signal.offset_left = third + (W - third) / 2.0 - 100
	no_signal.offset_right = third + (W - third) / 2.0 + 100
	no_signal.offset_top = -20
	no_signal.offset_bottom = 20
	no_signal.add_theme_font_size_override("font_size", 28)
	no_signal.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1.0))
	add_child(no_signal)

	var separator := ColorRect.new()
	separator.color = Color(0.0, 0.0, 0.0, 0.5)
	separator.set_anchors_preset(Control.PRESET_FULL_RECT)
	separator.offset_left = third - 1
	separator.offset_right = third + 1
	add_child(separator)

	log_label = RichTextLabel.new()
	log_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	log_label.offset_left = 15
	log_label.offset_top = 15
	log_label.offset_right = third - 15
	log_label.offset_bottom = -100
	log_label.bbcode_enabled = true
	log_label.scroll_following = true
	log_label.clip_contents = true
	log_label.add_theme_font_size_override("normal_font_size", 14)
	log_label.add_theme_color_override("default_color", Color(0.3, 1.0, 0.3))
	add_child(log_label)

	input_label = Label.new()
	input_label.text = "> "
	input_label.position = Vector2(15, H - 70)
	input_label.add_theme_font_size_override("font_size", 14)
	input_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	add_child(input_label)

	input_field = LineEdit.new()
	input_field.position = Vector2(35, H - 72)
	input_field.size = Vector2(third - 55, 26)
	input_field.add_theme_font_size_override("font_size", 14)
	input_field.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	input_field.add_theme_color_override("caret_color", Color(0.3, 1.0, 0.3))
	input_field.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	input_field.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	input_field.placeholder_text = "введите команду..."
	input_field.add_theme_color_override("font_placeholder_color", Color(0.1, 0.4, 0.1))
	input_field.text_submitted.connect(_on_text_submitted)
	add_child(input_field)

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
					input_field.call_deferred("grab_focus")

	if input_mode != "" and not input_field.has_focus():
		input_field.call_deferred("grab_focus")

func _on_text_submitted(text: String) -> void:
	var cmd := text.strip_edges().to_upper()
	input_field.text = ""
	_append_log("> " + cmd)

	match input_mode:
		"connect":
			_handle_connect(cmd)
		"action_menu":
			_handle_action_menu(cmd)
		"device":
			_handle_device(cmd)
		"camera_menu":
			_handle_camera_menu(cmd)
		"open_confirm":
			_handle_open_confirm(cmd)
		"code":
			_handle_code(cmd)
		"camera":
			_handle_camera_control(cmd)

func _ensure_focus() -> void:
	input_field.call_deferred("grab_focus")

func _handle_connect(cmd: String) -> void:
	if cmd == "Y":
		_append_log("УСТАНАВЛИВАЮ СОЕДИНЕНИЕ...")
		state = State.CONNECTING
		input_mode = ""
		await get_tree().create_timer(2.5).timeout
		_go_to_surveillance()
		_ensure_focus()
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
	_append_log("ВВЕДИТЕ 1 ДЛЯ МЕНЮ ДЕЙСТВИЙ.")

	var no_signal = get_node_or_null("NoSignal")
	if no_signal:
		no_signal.visible = false
	var bg_right = get_node_or_null("BgRight")
	if bg_right:
		bg_right.visible = false

	var W := get_viewport_rect().size.x
	var H := get_viewport_rect().size.y
	var third := W / 3.0
	var right_width := W - third

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

	world_camera = world_scene.get_node_or_null("Camera3D")
	camera2 = world_scene.get_node_or_null("Camera2")

	_set_active_camera(1)

	input_mode = "action_menu"
	_show_action_menu()
	_ensure_focus()

func _set_active_camera(cam_num: int) -> void:
	if world_camera:
		world_camera.current = (cam_num == 1)
	if camera2:
		camera2.current = (cam_num == 2)

func _toggle_dual_mode() -> void:
	var W := get_viewport_rect().size.x
	var H := get_viewport_rect().size.y
	var third := W / 3.0
	var right_width := W - third

	if not dual_mode:
		if not gate_opened:
			_append_log("РЕЖИМ ДВУХ КАМЕР НЕДОСТУПЕН. СНАЧАЛА ОТКРОЙТЕ ВОРОТА.")
			_ensure_focus()
			return

		var world_packed: PackedScene = load("res://scenes/world.tscn")
		world_scene2 = world_packed.instantiate()
		world_scene2.name = "WorldInstance2"
		sub_viewport2.add_child(world_scene2)

		camera2_copy = world_scene2.get_node_or_null("Camera2")

		if world_camera:
			world_camera.current = true
		if camera2:
			camera2.current = false
		if camera2_copy:
			camera2_copy.current = true

		if gate_opened and world_scene2.has_method("open_gate_instantly"):
			world_scene2.open_gate_instantly()

		sub_viewport.size = Vector2i(int(right_width), int(H / 2))
		tex_rect.size = Vector2(right_width, H / 2)
		tex_rect.position = Vector2(third, 0)

		sub_viewport2.size = Vector2i(int(right_width), int(H / 2))
		sub_viewport2.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		tex_rect2.size = Vector2(right_width, H / 2)
		tex_rect2.position = Vector2(third, H / 2)

		tex_rect2.visible = true

		dual_mode = true
		_append_log("РЕЖИМ ДВУХ КАМЕР АКТИВИРОВАН.")
		_append_log("  СВЕРХУ: КАМЕРА 1")
		_append_log("  СНИЗУ: КАМЕРА 2")
	else:
		if world_scene2:
			world_scene2.queue_free()
			world_scene2 = null
		camera2_copy = null

		sub_viewport.size = Vector2i(int(right_width), int(H))
		tex_rect.size = Vector2(right_width, H)
		tex_rect.position = Vector2(third, 0)

		sub_viewport2.render_target_update_mode = SubViewport.UPDATE_DISABLED
		tex_rect2.visible = false

		if world_camera:
			world_camera.current = true
		if camera2:
			camera2.current = false

		dual_mode = false
		_append_log("РЕЖИМ ОДНОЙ КАМЕРЫ АКТИВИРОВАН.")

	_ensure_focus()

func _show_action_menu() -> void:
	_append_log("")
	_append_log("=== МЕНЮ ДЕЙСТВИЙ ===")
	_append_log("1 - СКАНИРОВАТЬ УСТРОЙСТВА")
	_append_log("2 - ПОДКЛЮЧИТЬСЯ К УСТРОЙСТВУ")
	_append_log("3 - УПРАВЛЕНИЕ КАМЕРАМИ")
	_append_log("")
	_append_log("ВЫБЕРИТЕ ДЕЙСТВИЕ:")
	input_mode = "action_menu"

func _handle_action_menu(cmd: String) -> void:
	match cmd:
		"1":
			_append_log("СКАНИРОВАНИЕ УСТРОЙСТВ...")
			await get_tree().create_timer(1.5).timeout
			devices_scanned = true
			_append_log("СКАНИРОВАНИЕ ЗАВЕРШЕНО.")
			_append_log("ОБНАРУЖЕНЫ УСТРОЙСТВА:")
			_append_log("  - ВОРОТА (ДВЕРЬ 1)")
			_append_log("")
			_append_log("ВВЕДИТЕ 2 ДЛЯ ПОДКЛЮЧЕНИЯ К УСТРОЙСТВУ.")
			input_mode = "action_menu"
			_ensure_focus()
		"2":
			_append_log("ДОСТУПНЫЕ УСТРОЙСТВА:")
			if devices_scanned:
				_append_log("  1 - ВОРОТА (ДВЕРЬ 1)")
			_append_log("  0 - НАЗАД")
			_append_log("")
			_append_log("ВВЕДИТЕ НОМЕР УСТРОЙСТВА:")
			input_mode = "device"
			_ensure_focus()
		"3":
			_append_log("ДОСТУПНЫЕ КАМЕРЫ:")
			_append_log("  1 - КАМЕРА 1")
			if gate_opened:
				_append_log("  2 - КАМЕРА 2")
				_append_log("  3 - РЕЖИМ ДВУХ КАМЕР")
			_append_log("  0 - НАЗАД")
			_append_log("")
			_append_log("ВЫБЕРИТЕ КАМЕРУ:")
			input_mode = "camera_menu"
			_ensure_focus()
		_:
			_append_log("НЕВЕРНЫЙ ВЫБОР. ВВЕДИТЕ 1, 2 ИЛИ 3.")
			_ensure_focus()

func _handle_device(cmd: String) -> void:
	if cmd == "0":
		_append_log("ВОЗВРАТ В МЕНЮ ДЕЙСТВИЙ.")
		_show_action_menu()
		_ensure_focus()
		return
	if not cmd.is_valid_int():
		_append_log("ВВЕДИТЕ ЧИСЛО.")
		_ensure_focus()
		return
	var num := int(cmd)
	match num:
		1:
			if not devices_scanned:
				_append_log("УСТРОЙСТВО НЕ ОБНАРУЖЕНО. СНАЧАЛА ПРОСКАНИРУЙТЕ СИСТЕМУ.")
				_ensure_focus()
				return
			selected_device = 1
			_append_log("ПОДКЛЮЧЕНИЕ К ВОРОТАМ...")
			await get_tree().create_timer(1.0).timeout
			_append_log("СОЕДИНЕНИЕ УСТАНОВЛЕНО. ОТКРЫТЬ ВОРОТА? (Y/N)")
			_append_log("ВВЕДИТЕ 0 ДЛЯ ОТМЕНЫ.")
			input_mode = "open_confirm"
			_ensure_focus()
		_:
			_append_log("НЕВЕРНЫЙ НОМЕР УСТРОЙСТВА. ВВЕДИТЕ 0-1.")
			_ensure_focus()

func _handle_camera_menu(cmd: String) -> void:
	if cmd == "0":
		_append_log("ВОЗВРАТ В МЕНЮ ДЕЙСТВИЙ.")
		_show_action_menu()
		_ensure_focus()
		return
	if not cmd.is_valid_int():
		_append_log("ВВЕДИТЕ ЧИСЛО.")
		_ensure_focus()
		return
	var num := int(cmd)
	match num:
		1:
			if dual_mode:
				_toggle_dual_mode()
			_set_active_camera(1)
			selected_device = 2
			zoom_level = 1.0
			_append_log("ПОДКЛЮЧЕНИЕ К КАМЕРЕ 1...")
			await get_tree().create_timer(1.0).timeout
			_append_log("КАМЕРА 1 АКТИВИРОВАНА.")
			_append_log("")
			_append_log("УПРАВЛЕНИЕ КАМЕРОЙ:")
			_append_log("  R<число> - ПОВЕРНУТЬ (например R15 или R-15)")
			_append_log("  S<число> - ПРИБЛИЗИТЬ (например S0.5)")
			_append_log("  0 - ВЫЙТИ")
			_append_log("")
			_append_log("ВВЕДИТЕ КОМАНДУ:")
			input_mode = "camera"
			_ensure_focus()
		2:
			if not gate_opened:
				_append_log("КАМЕРА 2 НЕДОСТУПНА. СНАЧАЛА ОТКРОЙТЕ ВОРОТА.")
				_ensure_focus()
				return
			if dual_mode:
				_toggle_dual_mode()
			_set_active_camera(2)
			selected_device = 3
			zoom_level = 1.0
			_append_log("ПОДКЛЮЧЕНИЕ К КАМЕРЕ 2...")
			await get_tree().create_timer(1.0).timeout
			_append_log("КАМЕРА 2 АКТИВИРОВАНА.")
			_append_log("")
			_append_log("УПРАВЛЕНИЕ КАМЕРОЙ 2:")
			_append_log("  R<число> - ПОВЕРНУТЬ (например R15 или R-15)")
			_append_log("  S<число> - ПРИБЛИЗИТЬ (например S0.5)")
			_append_log("  0 - ВЫЙТИ")
			_append_log("")
			_append_log("ВВЕДИТЕ КОМАНДУ:")
			input_mode = "camera"
			_ensure_focus()
		3:
			if not gate_opened:
				_append_log("РЕЖИМ ДВУХ КАМЕР НЕДОСТУПЕН. СНАЧАЛА ОТКРОЙТЕ ВОРОТА.")
				_ensure_focus()
				return
			_toggle_dual_mode()
			zoom_level = 1.0
			_append_log("")
			_append_log("УПРАВЛЕНИЕ КАМЕРАМИ (DUAL MODE):")
			_append_log("  R<число> - ПОВЕРНУТЬ ОБЕ КАМЕРЫ")
			_append_log("  S<число> - ПРИБЛИЗИТЬ ОБЕ КАМЕРЫ")
			_append_log("  0 - ВЫЙТИ")
			_append_log("")
			_append_log("ВВЕДИТЕ КОМАНДУ:")
			input_mode = "camera"
			_ensure_focus()
		_:
			_append_log("НЕВЕРНЫЙ НОМЕР. ВВЕДИТЕ 0-3.")
			_ensure_focus()

func _handle_camera_control(cmd: String) -> void:
	if cmd == "0":
		if dual_mode:
			_toggle_dual_mode()
		_append_log("ВЫХОД ИЗ РЕЖИМА КАМЕРЫ.")
		_show_action_menu()
		_ensure_focus()
		return

	if dual_mode:
		# В dual mode применяем к ОБОИМ камерам
		if cmd.begins_with("R"):
			var angle_str := cmd.substr(1)
			if angle_str.is_valid_float():
				var angle: float = angle_str.to_float()
				if world_camera:
					var target1: float = world_camera.rotation.y + deg_to_rad(angle)
					var tween1 := create_tween()
					tween1.tween_property(world_camera, "rotation:y", target1, 0.8).set_ease(Tween.EASE_IN_OUT)
				if camera2_copy:
					var target2: float = camera2_copy.rotation.y + deg_to_rad(angle)
					var tween2 := create_tween()
					tween2.tween_property(camera2_copy, "rotation:y", target2, 0.8).set_ease(Tween.EASE_IN_OUT)
				_append_log("ОБЕ КАМЕРЫ ПОВОРАЧИВАЮТСЯ НА " + str(angle) + " ГРАДУСОВ.")
			else:
				_append_log("НЕВЕРНЫЙ ФОРМАТ. ИСПОЛЬЗУЙТЕ R<число>.")
		elif cmd.begins_with("S"):
			var zoom_str := cmd.substr(1)
			if zoom_str.is_valid_float():
				var zoom_change: float = zoom_str.to_float()
				var new_zoom: float = clampf(zoom_level + zoom_change, 0.5, 2.0)
				var target_fov: float = clampf(70.0 / new_zoom, 35.0, 90.0)
				if world_camera:
					var tween1 := create_tween()
					tween1.tween_property(world_camera, "fov", target_fov, 0.6).set_ease(Tween.EASE_IN_OUT)
				if camera2_copy:
					var tween2 := create_tween()
					tween2.tween_property(camera2_copy, "fov", target_fov, 0.6).set_ease(Tween.EASE_IN_OUT)
				zoom_level = new_zoom
				_append_log("ОБЕ КАМЕРЫ: ПРИБЛИЖЕНИЕ x" + str(snapped(zoom_level, 0.1)) + " (макс. 2x)")
			else:
				_append_log("НЕВЕРНЫЙ ФОРМАТ. ИСПОЛЬЗУЙТЕ S<число>.")
		else:
			_append_log("НЕИЗВЕСТНАЯ КОМАНДА. ИСПОЛЬЗУЙТЕ R<угол> или S<зум>.")
	else:
		# В single mode применяем к одной камере
		var active_cam: Camera3D = world_camera if selected_device != 3 else camera2

		if cmd.begins_with("R"):
			var angle_str := cmd.substr(1)
			if angle_str.is_valid_float():
				var angle: float = angle_str.to_float()
				if active_cam != null:
					var target_rotation: float = active_cam.rotation.y + deg_to_rad(angle)
					var tween := create_tween()
					tween.tween_property(active_cam, "rotation:y", target_rotation, 0.8).set_ease(Tween.EASE_IN_OUT)
				_append_log("КАМЕРА ПЛАВНО ПОВОРАЧИВАЕТСЯ НА " + str(angle) + " ГРАДУСОВ.")
			else:
				_append_log("НЕВЕРНЫЙ ФОРМАТ. ИСПОЛЬЗУЙТЕ R<число>.")
		elif cmd.begins_with("S"):
			var zoom_str := cmd.substr(1)
			if zoom_str.is_valid_float():
				var zoom_change: float = zoom_str.to_float()
				var new_zoom: float = clampf(zoom_level + zoom_change, 0.5, 2.0)
				var target_fov: float = clampf(70.0 / new_zoom, 35.0, 90.0)
				if active_cam != null:
					var tween := create_tween()
					tween.tween_property(active_cam, "fov", target_fov, 0.6).set_ease(Tween.EASE_IN_OUT)
				zoom_level = new_zoom
				_append_log("ПЛАВНОЕ ПРИБЛИЖЕНИЕ: x" + str(snapped(zoom_level, 0.1)) + " (макс. 2x)")
			else:
				_append_log("НЕВЕРНЫЙ ФОРМАТ. ИСПОЛЬЗУЙТЕ S<число>.")
		else:
			_append_log("НЕИЗВЕСТНАЯ КОМАНДА. ИСПОЛЬЗУЙТЕ R<угол> или S<зум>.")

	_ensure_focus()

func _handle_open_confirm(cmd: String) -> void:
	if cmd == "0":
		_append_log("ОТМЕНА.")
		_show_action_menu()
		_ensure_focus()
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
	_ensure_focus()

func _handle_code(cmd: String) -> void:
	if cmd == "0":
		_append_log("ОТМЕНА ВВОДА КОДА.")
		_show_action_menu()
		_ensure_focus()
		return
	if not cmd.is_valid_int():
		_append_log("КОД ДОЛЖЕН СОСТОЯТЬ ТОЛЬКО ИЗ ЦИФР.")
		_ensure_focus()
		return
	var code := int(cmd)
	if code == gate_code:
		_append_log("КОД ПРИНЯТ. ОТКРЫВАЮ ВОРОТА...")
		_open_gate_direct()
		_append_log("ВОРОТА ОТКРЫТЫ.")
		gate_opened = true
		_show_action_menu()
	else:
		_append_log("НЕВЕРНЫЙ КОД. ПОПРОБУЙТЕ СНОВА.")
		_append_log("ВВЕДИТЕ 0 ДЛЯ ОТМЕНЫ.")
	_ensure_focus()

func _open_gate_direct() -> void:
	if world_scene and world_scene.has_method("open_gate"):
		world_scene.open_gate()
	if world_scene2 and world_scene2.has_method("open_gate"):
		world_scene2.open_gate()

func _append_log(text: String) -> void:
	log_label.text += text + "\n"
