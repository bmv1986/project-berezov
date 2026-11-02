extends Control

signal command_entered(cmd: String)

var output_label: RichTextLabel
var scroll_container: ScrollContainer
var input_field: LineEdit
var is_input_enabled: bool = true

func _ready() -> void:
	_build_ui()
	await get_tree().process_frame
	input_field.grab_focus()

func _build_ui() -> void:
	var screen_size := get_viewport_rect().size
	var third_width := screen_size.x / 3.0

	# === ФОН (левая треть) ===
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.85)
	bg.size = Vector2(third_width, screen_size.y)
	bg.position = Vector2(0, 0)
	bg.set_anchors_preset(0)
	bg.offset_right = third_width
	bg.offset_bottom = screen_size.y
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	# === SCROLL CONTAINER ===
	scroll_container = ScrollContainer.new()
	scroll_container.size = Vector2(third_width - 40, screen_size.y - 100)
	scroll_container.position = Vector2(20, 30)
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll_container)

	# === ОБЛАСТЬ ТЕКСТА ===
	output_label = RichTextLabel.new()
	output_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	output_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	output_label.bbcode_enabled = false
	output_label.fit_content = false
	output_label.scroll_active = true
	output_label.add_theme_font_size_override("normal_font_size", 18)
	output_label.add_theme_color_override("default_color", Color(0.2, 1.0, 0.5))
	scroll_container.add_child(output_label)

	# === ПОЛЕ ВВОДА ===
	input_field = LineEdit.new()
	input_field.size = Vector2(third_width - 40, 45)
	input_field.position = Vector2(20, screen_size.y - 70)
	input_field.add_theme_font_size_override("font_size", 18)
	input_field.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
	input_field.add_theme_color_override("caret_color", Color(0.2, 1.0, 0.5))
	input_field.add_theme_color_override("placeholder_color", Color(0.1, 0.4, 0.2))
	input_field.placeholder_text = "> Введите команду..."
	input_field.text_submitted.connect(_on_text_submitted)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 1.0)
	style.border_color = Color(0.2, 1.0, 0.5)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	input_field.add_theme_stylebox_override("normal", style)
	input_field.add_theme_stylebox_override("focus", style)
	
	add_child(input_field)

func start_boot_sequence(lines: Array[String]) -> void:
	output_label.text = ""
	for line in lines:
		output_label.text += line + "\n"
		_scroll_to_bottom()
		await get_tree().create_timer(0.4).timeout
	output_label.text += "\n"
	_scroll_to_bottom()
	command_entered.emit("__boot_finished__")

func append_log(text: String) -> void:
	output_label.text += text + "\n"
	_scroll_to_bottom()

func show_command_hint(hint: String) -> void:
	# Показывает подсказку о доступных командах
	output_label.text += "\n" + hint + "\n"
	_scroll_to_bottom()

func _scroll_to_bottom() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	
	var v_scroll = scroll_container.get_v_scroll_bar()
	if v_scroll:
		v_scroll.value = v_scroll.max_value

func _on_text_submitted(text: String) -> void:
	if not is_input_enabled:
		return
	if text.strip_edges().is_empty():
		return
	
	output_label.text += "> " + text + "\n"
	_scroll_to_bottom()
	input_field.clear()
	command_entered.emit(text)

func set_input_enabled(enabled: bool) -> void:
	is_input_enabled = enabled
	input_field.editable = enabled
	if enabled:
		input_field.grab_focus()

func focus_input() -> void:
	if is_input_enabled:
		input_field.grab_focus()

func unfocus_input() -> void:
	input_field.release_focus()

func hide_signal_screen() -> void:
	pass
