extends Control

signal command_entered(cmd: String)

var log_label: RichTextLabel
var input_label: Label
var input_field: LineEdit
var bg_right: ColorRect
var no_signal: Label

var boot_lines: Array[String] = []
var current_line_index: int = 0
var char_index: int = 0
var boot_timer: float = 0.0
var is_booting: bool = false
var input_enabled: bool = true

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var W: float = get_viewport_rect().size.x
	var H: float = get_viewport_rect().size.y
	var third: float = W / 3.0

	var bg_left := ColorRect.new()
	bg_left.color = Color(0.05, 0.05, 0.08, 1.0)
	bg_left.set_anchors_preset(15)
	bg_left.offset_right = third
	add_child(bg_left)

	bg_right = ColorRect.new()
	bg_right.color = Color(0.0, 0.0, 0.0, 1.0)
	bg_right.set_anchors_preset(15)
	bg_right.offset_left = third
	add_child(bg_right)

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

	var separator := ColorRect.new()
	separator.color = Color(0.0, 0.0, 0.0, 0.5)
	separator.set_anchors_preset(15)
	separator.offset_left = third - 1
	separator.offset_right = third + 1
	add_child(separator)

	log_label = RichTextLabel.new()
	log_label.set_anchors_preset(15)
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

func _on_text_submitted(text: String) -> void:
	var cmd: String = text.strip_edges().to_upper()
	input_field.text = ""
	append_log("> " + cmd)
	command_entered.emit(cmd)

func append_log(text: String) -> void:
	log_label.text += text + "\n"

func clear_log() -> void:
	log_label.text = ""

func hide_signal_screen() -> void:
	if no_signal:
		no_signal.visible = false
	if bg_right:
		bg_right.visible = false

func start_boot_sequence(lines: Array[String]) -> void:
	boot_lines = lines
	current_line_index = 0
	char_index = 0
	boot_timer = 0.0
	is_booting = true
	input_enabled = false
	log_label.text = ""

func stop_boot_sequence() -> void:
	is_booting = false
	input_enabled = true

func is_booting_active() -> bool:
	return is_booting

func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled
	if enabled:
		input_field.visible = true
		focus_input()
	else:
		input_field.visible = false
		unfocus_input()
		if input_field:
			input_field.text = ""

func is_input_enabled() -> bool:
	return input_enabled

func focus_input() -> void:
	if input_enabled and input_field.visible:
		input_field.call_deferred("grab_focus")

func unfocus_input() -> void:
	input_field.release_focus()

func _process(delta: float) -> void:
	if is_booting:
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
					stop_boot_sequence()
					command_entered.emit("__boot_finished__")

	# Фокус только если поле видимо
	if input_enabled and not input_field.has_focus() and input_field.visible:
		focus_input()
