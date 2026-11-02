extends Control

signal update_finished()

var progress_bar: ProgressBar
var status_label: Label
var stage: int = 0
var timer: float = 0.0
var _rebooting: bool = false

const STAGES = [
	"> Инициализация загрузчика...",
	"> Проверка целостности ядра...",
	"> Загрузка модулей безопасности...",
	"> Обновление драйверов устройств...",
	"> Установка патчей безопасности v4.0.1...",
	"> Оптимизация системы...",
	"> Настройка сетевого интерфейса...",
	"> Интеграция графической оболочки NEXUS GUI...",
	"> Финализация установки...",
	"> Подготовка к перезагрузке..."
]

func _ready() -> void:
	_build_ui()
	visible = false

func _build_ui() -> void:
	# Получаем размер экрана
	var screen_size := get_viewport_rect().size
	
	# === ЧЁРНЫЙ ФОН НА ВЕСЬ ЭКРАН ===
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 1)
	bg.size = screen_size
	bg.position = Vector2(0, 0)
	add_child(bg)

	# === ЦЕНТРАЛЬНАЯ ПАНЕЛЬ (600x400 по центру) ===
	var panel_width := 600
	var panel_height := 400
	var panel_x := (screen_size.x - panel_width) / 2
	var panel_y := (screen_size.y - panel_height) / 2
	
	var panel := ColorRect.new()
	panel.color = Color(0.05, 0.05, 0.05, 1)
	panel.size = Vector2(panel_width, panel_height)
	panel.position = Vector2(panel_x, panel_y)
	add_child(panel)

	# === ЗАГОЛОВОК В СТИЛЕ СПЕКТРУМА ===
	var title_y := panel_y + 40
	var title := Label.new()
	title.text = "╔════════════════════════════════════════╗"
	title.size = Vector2(panel_width, 20)
	title.position = Vector2(panel_x, title_y)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0, 1, 0.3))
	add_child(title)

	var title2 := Label.new()
	title2.text = "║   УСТАНОВКА НОВОЙ ОБОЛОЧКИ NEXUS   ║"
	title2.size = Vector2(panel_width, 20)
	title2.position = Vector2(panel_x, title_y + 25)
	title2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title2.add_theme_font_size_override("font_size", 18)
	title2.add_theme_color_override("font_color", Color(0, 1, 0.3))
	add_child(title2)

	var title3 := Label.new()
	title3.text = "╚════════════════════════════════════════╝"
	title3.size = Vector2(panel_width, 20)
	title3.position = Vector2(panel_x, title_y + 50)
	title3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title3.add_theme_font_size_override("font_size", 18)
	title3.add_theme_color_override("font_color", Color(0, 1, 0.3))
	add_child(title3)

	# === ВЕРСИЯ ===
	var version_y := panel_y + 130
	var version := Label.new()
	version.text = "NEXUS OS v3.7.2 -> v4.0.1"
	version.size = Vector2(panel_width, 20)
	version.position = Vector2(panel_x, version_y)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.add_theme_font_size_override("font_size", 16)
	version.add_theme_color_override("font_color", Color(0, 0.8, 0.3))
	add_child(version)

	# === СТАТУС ===
	var status_y := panel_y + 180
	status_label = Label.new()
	status_label.text = "> Подготовка..."
	status_label.size = Vector2(panel_width - 40, 20)
	status_label.position = Vector2(panel_x + 20, status_y)
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color(0, 1, 0.3))
	add_child(status_label)

	# === ПРОГРЕСС-БАР ===
	var bar_y := panel_y + 220
	progress_bar = ProgressBar.new()
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.value = 0
	progress_bar.size = Vector2(panel_width - 40, 25)
	progress_bar.position = Vector2(panel_x + 20, bar_y)
	progress_bar.show_percentage = false
	add_child(progress_bar)

	# === ПРОЦЕНТ ===
	var percent_label := Label.new()
	percent_label.name = "PercentLabel"
	percent_label.size = Vector2(panel_width, 20)
	percent_label.position = Vector2(panel_x, bar_y + 30)
	percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	percent_label.add_theme_font_size_override("font_size", 16)
	percent_label.add_theme_color_override("font_color", Color(0, 1, 0.3))
	add_child(percent_label)

	# === ПРЕДУПРЕЖДЕНИЕ ===
	var warning_y := panel_y + panel_height - 50
	var warning := Label.new()
	warning.text = "!!! НЕ ВЫКЛЮЧАЙТЕ СИСТЕМУ !!!"
	warning.size = Vector2(panel_width, 20)
	warning.position = Vector2(panel_x, warning_y)
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning.add_theme_font_size_override("font_size", 16)
	warning.add_theme_color_override("font_color", Color(1, 0.5, 0))
	add_child(warning)

func start_update() -> void:
	visible = true
	_rebooting = false
	stage = 0
	timer = 0.0
	progress_bar.value = 0
	status_label.text = STAGES[0]
	_update_percent()

func _update_percent() -> void:
	var percent_label = get_node_or_null("PercentLabel")
	if percent_label:
		percent_label.text = "[%d%%]" % int(progress_bar.value)

func _process(delta: float) -> void:
	if not visible:
		return

	timer += delta
	if timer >= 0.3:
		timer = 0.0
		progress_bar.value += 1.5

		var new_stage: int = int(progress_bar.value / (100.0 / STAGES.size()))
		if new_stage != stage and new_stage < STAGES.size():
			stage = new_stage
			status_label.text = STAGES[stage]

		_update_percent()

		if progress_bar.value >= 100:
			progress_bar.value = 100
			status_label.text = "> Установка завершена. Перезагрузка..."
			_update_percent()
			if not _rebooting:
				_rebooting = true
				_reboot()

func _reboot() -> void:
	await get_tree().create_timer(2.0).timeout
	visible = false
	_rebooting = false
	update_finished.emit()
	print(">>> OSUpdate: сигнал update_finished эмитирован")
