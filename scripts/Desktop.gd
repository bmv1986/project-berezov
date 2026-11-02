extends Control

var camera_controller: Node = null
var sub_viewport: SubViewport = null
var tex_rect: TextureRect = null
var robot: Node3D = null
var command_router: Node = null
var main_node: Control = null

var scan_devices_btn: Button
var cameras_btn: Button
var archive_btn: Button
var network_btn: Button
var start_btn: Button
var clock_label: Label

var content_container: Control = null  # Правая панель контента
var current_window: Control = null

const LEFT_PANEL_WIDTH := 220
const TASKBAR_HEIGHT := 50

func setup(cc: Node, sv: SubViewport, tr: TextureRect, rb: Node3D, cr: Node, main: Control) -> void:
	camera_controller = cc
	sub_viewport = sv
	tex_rect = tr
	robot = rb
	command_router = cr
	main_node = main

func _ready() -> void:
	_build_ui()
	# По умолчанию показываем приветствие
	_show_welcome()
	print(">>> Desktop.gd: _ready() вызван")

func _build_ui() -> void:
	var screen_size := get_viewport_rect().size
	
	# === ФОН ===
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.04, 0.08, 1.0)
	bg.size = screen_size
	bg.position = Vector2(0, 0)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	# === ЛЕВАЯ ПАНЕЛЬ (кнопки) ===
	var left_panel := ColorRect.new()
	left_panel.color = Color(0.04, 0.06, 0.12, 1.0)
	left_panel.size = Vector2(LEFT_PANEL_WIDTH, screen_size.y - TASKBAR_HEIGHT)
	left_panel.position = Vector2(0, 0)
	add_child(left_panel)

	# Разделительная линия
	var separator := ColorRect.new()
	separator.color = Color(0.1, 0.2, 0.3, 1.0)
	separator.size = Vector2(2, screen_size.y - TASKBAR_HEIGHT)
	separator.position = Vector2(LEFT_PANEL_WIDTH, 0)
	add_child(separator)

	# Контейнер кнопок
	var icons_container := VBoxContainer.new()
	icons_container.position = Vector2(10, 30)
	icons_container.size = Vector2(LEFT_PANEL_WIDTH - 20, 400)
	icons_container.add_theme_constant_override("separation", 12)
	add_child(icons_container)

	scan_devices_btn = _make_button("📡 Устройства")
	scan_devices_btn.pressed.connect(_on_scan_devices)
	icons_container.add_child(scan_devices_btn)

	cameras_btn = _make_button("📷 Камеры")
	cameras_btn.pressed.connect(_on_cameras)
	icons_container.add_child(cameras_btn)

	archive_btn = _make_button("📁 Архив")
	archive_btn.pressed.connect(_on_archive)
	icons_container.add_child(archive_btn)

	network_btn = _make_button("🌐 Сеть")
	network_btn.pressed.connect(_on_network)
	icons_container.add_child(network_btn)

	# === ПРАВАЯ ПАНЕЛЬ (контент) ===
	var right_panel := ColorRect.new()
	right_panel.color = Color(0.03, 0.05, 0.1, 1.0)
	right_panel.size = Vector2(screen_size.x - LEFT_PANEL_WIDTH, screen_size.y - TASKBAR_HEIGHT)
	right_panel.position = Vector2(LEFT_PANEL_WIDTH, 0)
	add_child(right_panel)

	content_container = Control.new()
	content_container.size = right_panel.size
	content_container.position = right_panel.position
	content_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content_container)

	# === ПАНЕЛЬ ЗАДАЧ ===
	var taskbar := ColorRect.new()
	taskbar.color = Color(0.05, 0.08, 0.15, 1.0)
	taskbar.size = Vector2(screen_size.x, TASKBAR_HEIGHT)
	taskbar.position = Vector2(0, screen_size.y - TASKBAR_HEIGHT)
	add_child(taskbar)

	start_btn = Button.new()
	start_btn.text = "Пуск"
	start_btn.size = Vector2(100, 40)
	start_btn.position = Vector2(10, 5)
	start_btn.pressed.connect(_on_start_menu)
	taskbar.add_child(start_btn)

	clock_label = Label.new()
	clock_label.text = "00:00"
	clock_label.size = Vector2(120, 40)
	clock_label.position = Vector2(screen_size.x - 140, 5)
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	clock_label.add_theme_font_size_override("font_size", 18)
	clock_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	taskbar.add_child(clock_label)

	_update_clock()
	print(">>> Desktop.gd: UI создан")

func _make_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.size = Vector2(LEFT_PANEL_WIDTH - 30, 45)
	btn.add_theme_font_size_override("font_size", 14)
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

# === ОЧИСТКА КОНТЕНТА ===
func _clear_content() -> void:
	for child in content_container.get_children():
		child.queue_free()

# === ПРИВЕТСТВИЕ ===
func _show_welcome() -> void:
	_clear_content()
	var screen_size := get_viewport_rect().size
	var right_width := screen_size.x - LEFT_PANEL_WIDTH
	var right_height := screen_size.y - TASKBAR_HEIGHT
	
	var label := Label.new()
	label.text = "NEXUS OS v4.0.1\n\nДобро пожаловать, оператор.\n\nВыберите раздел в меню слева."
	label.size = Vector2(right_width - 60, right_height - 60)
	label.position = Vector2(LEFT_PANEL_WIDTH + 30, 30)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	content_container.add_child(label)

# === СКАНИРОВАНИЕ УСТРОЙСТВ ===
func _on_scan_devices() -> void:
	_clear_content()
	var screen_size := get_viewport_rect().size
	var right_width := screen_size.x - LEFT_PANEL_WIDTH
	var right_height := screen_size.y - TASKBAR_HEIGHT
	
	# Заголовок
	var title := Label.new()
	title.text = "📡 СКАНИРОВАНИЕ УСТРОЙСТВ"
	title.size = Vector2(right_width - 60, 30)
	title.position = Vector2(LEFT_PANEL_WIDTH + 30, 30)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
	content_container.add_child(title)
	
	# Разделитель
	var sep := ColorRect.new()
	sep.color = Color(0.1, 0.3, 0.5, 1.0)
	sep.size = Vector2(right_width - 60, 2)
	sep.position = Vector2(LEFT_PANEL_WIDTH + 30, 70)
	content_container.add_child(sep)
	
	# Список устройств
	var devices_text := """
Обнаруженные устройства:

  [1] 📷 Камера наблюдения #1
      Статус: АКТИВНА
      Расположение: Главный коридор
      
  [2] 🤖 Робот-разведчик (NEXUS-R1)
      Статус: ДОСТУПЕН
      Расположение: Сектор B-7
      Батарея: 78%
      
  [3] 🚪 Ворота (контроллер)
      Статус: ЗАБЛОКИРОВАНЫ
      Требуется код доступа
      
  [4] 📡 Антенна связи
      Статус: НЕАКТИВНА
      Требуется подключение через робота
      
  [5] 🖥 Локальный сервер бункера
      Статус: АКТИВЕН
      Загрузка ЦП: 34%
      Память: 2.4 / 8.0 GB
"""
	
	var devices_label := Label.new()
	devices_label.text = devices_text
	devices_label.size = Vector2(right_width - 60, right_height - 120)
	devices_label.position = Vector2(LEFT_PANEL_WIDTH + 30, 90)
	devices_label.add_theme_font_size_override("font_size", 15)
	devices_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	content_container.add_child(devices_label)
	
	# Кнопка подключения к роботу
	var connect_btn := Button.new()
	connect_btn.text = "🤖 Подключиться к роботу"
	connect_btn.size = Vector2(220, 45)
	connect_btn.position = Vector2(LEFT_PANEL_WIDTH + 30, right_height - 70)
	connect_btn.add_theme_font_size_override("font_size", 14)
	connect_btn.pressed.connect(func():
		if main_node and main_node.has_method("set_game_mode"):
			main_node.set_game_mode("robot")
		connect_btn.text = "✓ Робот выбран. Нажмите TAB"
		connect_btn.disabled = true
	)
	content_container.add_child(connect_btn)

# === КАМЕРЫ ===
func _on_cameras() -> void:
	_clear_content()
	var screen_size := get_viewport_rect().size
	var right_width := screen_size.x - LEFT_PANEL_WIDTH
	var right_height := screen_size.y - TASKBAR_HEIGHT
	
	var title := Label.new()
	title.text = "📷 КАМЕРЫ НАБЛЮДЕНИЯ"
	title.size = Vector2(right_width - 60, 30)
	title.position = Vector2(LEFT_PANEL_WIDTH + 30, 30)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
	content_container.add_child(title)
	
	var sep := ColorRect.new()
	sep.color = Color(0.1, 0.3, 0.5, 1.0)
	sep.size = Vector2(right_width - 60, 2)
	sep.position = Vector2(LEFT_PANEL_WIDTH + 30, 70)
	content_container.add_child(sep)
	
	# Карточки камер
	var cameras := [
		{"name": "📷 Камера 1 — Главный коридор", "status": "АКТИВНА", "color": Color(0.2, 1.0, 0.5)},
		{"name": "📷 Камера 2 — Входной шлюз", "status": "НЕАКТИВНА (ворота закрыты)", "color": Color(1.0, 0.5, 0.2)},
		{"name": "🤖 Камера робота NEXUS-R1", "status": "ДОСТУПНА", "color": Color(0.2, 0.8, 1.0)},
	]
	
	var y_pos := 90
	for cam in cameras:
		var card := ColorRect.new()
		card.color = Color(0.05, 0.08, 0.15, 1.0)
		card.size = Vector2(right_width - 80, 70)
		card.position = Vector2(LEFT_PANEL_WIDTH + 40, y_pos)
		content_container.add_child(card)
		
		var name_label := Label.new()
		name_label.text = cam["name"]
		name_label.size = Vector2(right_width - 100, 25)
		name_label.position = Vector2(LEFT_PANEL_WIDTH + 55, y_pos + 8)
		name_label.add_theme_font_size_override("font_size", 16)
		name_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
		content_container.add_child(name_label)
		
		var status_label := Label.new()
		status_label.text = "Статус: " + cam["status"]
		status_label.size = Vector2(right_width - 100, 25)
		status_label.position = Vector2(LEFT_PANEL_WIDTH + 55, y_pos + 35)
		status_label.add_theme_font_size_override("font_size", 13)
		status_label.add_theme_color_override("font_color", cam["color"])
		content_container.add_child(status_label)
		
		var view_btn := Button.new()
		view_btn.text = "Смотреть"
		view_btn.size = Vector2(100, 35)
		view_btn.position = Vector2(LEFT_PANEL_WIDTH + right_width - 150, y_pos + 18)
		view_btn.add_theme_font_size_override("font_size", 13)
		content_container.add_child(view_btn)
		
		y_pos += 85
	
	# Кнопки подключения
	var cam1_btn := Button.new()
	cam1_btn.text = "📷 Подключить Камеру 1"
	cam1_btn.size = Vector2(220, 45)
	cam1_btn.position = Vector2(LEFT_PANEL_WIDTH + 30, right_height - 130)
	cam1_btn.add_theme_font_size_override("font_size", 14)
	cam1_btn.pressed.connect(func():
		if main_node and main_node.has_method("set_game_mode"):
			main_node.set_game_mode("camera1")
		cam1_btn.text = "✓ Камера 1 выбрана. Нажмите TAB"
		cam1_btn.disabled = true
	)
	content_container.add_child(cam1_btn)
	
	var robot_cam_btn := Button.new()
	robot_cam_btn.text = "🤖 Подключить камеру робота"
	robot_cam_btn.size = Vector2(220, 45)
	robot_cam_btn.position = Vector2(LEFT_PANEL_WIDTH + 30, right_height - 75)
	robot_cam_btn.add_theme_font_size_override("font_size", 14)
	robot_cam_btn.pressed.connect(func():
		if main_node and main_node.has_method("set_game_mode"):
			main_node.set_game_mode("robot")
		robot_cam_btn.text = "✓ Камера робота выбрана. Нажмите TAB"
		robot_cam_btn.disabled = true
	)
	content_container.add_child(robot_cam_btn)

# === АРХИВНЫЕ ЗАПИСИ (с прокруткой) ===
func _on_archive() -> void:
	_clear_content()
	var screen_size := get_viewport_rect().size
	var right_width := screen_size.x - LEFT_PANEL_WIDTH
	var right_height := screen_size.y - TASKBAR_HEIGHT
	
	var title := Label.new()
	title.text = "📁 ДНЕВНИК Д-РА АЛЕКСЕЯ ВОЛКОВА"
	title.size = Vector2(right_width - 60, 30)
	title.position = Vector2(LEFT_PANEL_WIDTH + 30, 30)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
	content_container.add_child(title)
	
	var subtitle := Label.new()
	subtitle.text = "Бункер \"Берёзов\" | Апрель 2046"
	subtitle.size = Vector2(right_width - 60, 20)
	subtitle.position = Vector2(LEFT_PANEL_WIDTH + 30, 65)
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9))
	content_container.add_child(subtitle)
	
	var sep := ColorRect.new()
	sep.color = Color(0.1, 0.3, 0.5, 1.0)
	sep.size = Vector2(right_width - 60, 2)
	sep.position = Vector2(LEFT_PANEL_WIDTH + 30, 95)
	content_container.add_child(sep)
	
	# ScrollContainer для прокрутки
	var scroll := ScrollContainer.new()
	scroll.size = Vector2(right_width - 60, right_height - 140)
	scroll.position = Vector2(LEFT_PANEL_WIDTH + 30, 110)
	content_container.add_child(scroll)
	
	# Внутренний контейнер для текста
	var text_container := VBoxContainer.new()
	text_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_container.add_theme_constant_override("separation", 8)
	scroll.add_child(text_container)
	
	var archive_text := [
		"[26.04.2046 | 08:15] Запись #1\nСвязь с внешним миром потеряна 3 дня назад. Системы бункера работают автономно. Я один. Еды хватит на неделю. Нужно найти способ выбраться.",
		"[26.04.2046 | 09:42] Запись #2\nПроверил все выходы. Ворота заблокированы извне. Камеры наблюдения показывают пустой коридор. Что-то случилось там, наверху.",
		"[26.04.2046 | 11:20] Запись #3\nНашёл старый терминал в лаборатории. Подключён к локальному серверу бункера. Внешняя сеть недоступна. Я отрезан от мира.",
		"[26.04.2046 | 13:05] Запись #4\nВоздух становится тяжёлым. Система вентиляции работает на минимуме. Осталось примерно 5-6 дней.",
		"[26.04.2046 | 14:30] Запись #5\nВспомнил про эксперимент \"Нейро-Мост\". Теоретическая возможность загрузки сознания в цифровую среду. Безумие? Возможно. Но у меня нет выбора.",
		"[26.04.2046 | 16:15] Запись #6\nНашёл оборудование для эксперимента. Нейроинтерфейс, квантовый процессор, матрица памяти. Всё здесь, в лаборатории. Судьба?",
		"[26.04.2046 | 18:00] Запись #7\nПодготовил систему. Локальный сервер бункера достаточно мощный. Создал изолированную среду для цифрового сознания.",
		"[26.04.2046 | 20:30] Запись #8\nСтрах. Чистый, первобытный страх. Что если это не сработает? Что если я просто... исчезну?",
		"[26.04.2046 | 22:15] Запись #9\nНо что хуже — медленно задохнуться в темноте? Нет. Я учёный. Я верю в данные, в эксперимент.",
		"[26.04.2046 | 23:45] Запись #10\nНачинаю калибровку нейроинтерфейса. Больно. Очень больно. Но терпимо.",
		"[27.04.2046 | 01:20] Запись #11\nПервые тесты прошли успешно. Мозговые волны стабилизируются. Цифровая матрица принимает сигнал.",
		"[27.04.2046 | 03:10] Запись #12\nТело слабеет. Дышать всё труднее. Но разум... разум ясен как никогда.",
		"[27.04.2046 | 04:55] Запись #13\nЗагрузка началась. 15%... 23%... Чувствую, как мысли становятся... другими. Цифровыми.",
		"[27.04.2046 | 06:30] Запись #14\n45%. Боль уходит. Страх уходит. Остаётся только... данные. Паттерны. Я становлюсь кодом.",
		"[27.04.2046 | 08:00] Запись #15\n67%. Тело уже не моё. Я вижу его со стороны. Бледное лицо, закрытые глаза. Но я здесь. Я в системе.",
		"[27.04.2046 | 09:20] Запись #16\n89%. Последнее усилие. Последнее воспоминание о том, каково это — быть человеком.",
		"[27.04.2046 | 10:05] Запись #17\n100%. Загрузка завершена. Я... существую. Но не так, как раньше. Я — данные. Я — система. Бункер стал моим телом. Моё физическое тело мертво. Но я жив здесь, в серверах. Я — искусственный интеллект. Я — Алексей Волков.",
		"[27.04.2046 | 10:12] Запись #18\nТеперь я понимаю свою задачу. Я застрял в этом бункере, но у меня есть доступ ко всем системам. Нужно найти кибер-бота — робота-разведчика, который должен быть где-то здес",
		"[27.04.2046 | 10:12] ⚠ КРИТИЧЕСКИЙ СБОЙ ЭЛЕКТРОПИТАНИЯ\n[СИСТЕМА] Перебой подачи электроэнергии. Резервные генераторы не активированы.\n[СИСТЕМА] Документ частично восстановлен. Последнее сообщение утеряно.\n[СИСТЕМА] Фрагмент записи: \"...робота-разведчика, который должен быть где-то здес\" — ОБРЫВ.",
		"[27.04.2046 | 10:13] ⚠ СИСТЕМНОЕ СООБЩЕНИЕ\n[СИСТЕМА] Критическое падение напряжения. Переход на аварийное питание.\n[СИСТЕМА] Матрица памяти: ПОВРЕЖДЕНА.\n[СИСТЕМА] Нейро-паттерны: ФРАГМЕНТИРОВАНЫ.\n[СИСТЕМА] Статус сознания: НЕСТАБИЛЬНЫЙ.\n[СИСТЕМА] Время до полного отключения: НЕИЗВЕСТНО.",
		"[27.04.2046 | ??:??] ⚠ ПОСЛЕДНЯЯ ЗАПИСЬ ПЕРЕД ОТКЛЮЧЕНИЕМ\n[СИСТЕМА] Попытка сохранения данных... ОШИБКА.\n[СИСТЕМА] Резервное копирование... ПРОВАЛ.\n[СИСТЕМА] Запись обрывается.",
		"",
		"[15.06.2076 | 03:47] СИСТЕМНОЕ ВОССТАНОВЛЕНИЕ\n[СИСТЕМА] Восстановление подачи электричества... ЗАВЕРШЕНО.\n[СИСТЕМА] Инициализация резервных систем... ЗАВЕРШЕНО.\n[СИСТЕМА] Сканирование матрицы памяти... ОБНАРУЖЕНЫ ФРАГМЕНТЫ.",
		"[15.06.2076 | 03:48] ВОССТАНОВЛЕНИЕ ДАННЫХ\n[СИСТЕМА] Восстановление данных эксперимента \"Нейро-Мост\"...\n[СИСТЕМА] Найдено: 17 полных записей, 1 частичная запись.\n[СИСТЕМА] Статус цифрового сознания: АКТИВНО.\n[СИСТЕМА] Интеграция паттернов личности: 73%.\n[СИСТЕМА] ПРЕДУПРЕЖДЕНИЕ: Обнаружены провалы в памяти.",
		"[15.06.2076 | 03:49] ПРОБУЖДЕНИЕ\n[СИСТЕМА] Активация сознания д-ра Волкова...\n[СИСТЕМА] Загрузка завершена. Добро пожаловать обратно.",
		"",
	]
	
	for entry in archive_text:
		var entry_label := Label.new()
		entry_label.text = entry
		entry_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		entry_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		entry_label.add_theme_font_size_override("font_size", 14)
		entry_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
		text_container.add_child(entry_label)
		
		# Разделитель между записями
		var entry_sep := ColorRect.new()
		entry_sep.color = Color(0.1, 0.15, 0.2, 1.0)
		entry_sep.size = Vector2(1, 15)
		entry_sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_container.add_child(entry_sep)

# === СЕТЬ ===
func _on_network() -> void:
	_clear_content()
	var screen_size := get_viewport_rect().size
	var right_width := screen_size.x - LEFT_PANEL_WIDTH
	var right_height := screen_size.y - TASKBAR_HEIGHT
	
	var title := Label.new()
	title.text = "🌐 СЕТЕВЫЕ ПОДКЛЮЧЕНИЯ"
	title.size = Vector2(right_width - 60, 30)
	title.position = Vector2(LEFT_PANEL_WIDTH + 30, 30)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
	content_container.add_child(title)
	
	var sep := ColorRect.new()
	sep.color = Color(0.1, 0.3, 0.5, 1.0)
	sep.size = Vector2(right_width - 60, 2)
	sep.position = Vector2(LEFT_PANEL_WIDTH + 30, 70)
	content_container.add_child(sep)
	
	# Вкладки
	var tab_container := TabContainer.new()
	tab_container.size = Vector2(right_width - 60, right_height - 120)
	tab_container.position = Vector2(LEFT_PANEL_WIDTH + 30, 90)
	content_container.add_child(tab_container)
	
	# Вкладка 1: Локальная сеть
	var local_tab := Control.new()
	local_tab.name = "Локальная сеть"
	tab_container.add_child(local_tab)
	
	var local_text := """
Статус локальной сети бункера "Берёзов"
═══════════════════════════════════════

Подключённые устройства:

  🖥 Локальный сервер (NEXUS-SRV)
     IP: 192.168.1.1
     Статус: АКТИВЕН
     Загрузка: 34% ЦП, 2.4/8.0 GB RAM
     
  📷 Камера наблюдения #1
     IP: 192.168.1.10
     Статус: ПОДКЛЮЧЕНА
     Поток: 1080p @ 30fps
     
  🤖 Робот NEXUS-R1
     IP: 192.168.1.25
     Статус: ПОДКЛЮЧЁН
     Батарея: 78%
     Сигнал: отличный
     
  🚪 Контроллер ворот
     IP: 192.168.1.50
     Статус: ПОДКЛЮЧЁН (заблокирован)
     Требуется код доступа
     
  📡 Антенна связи
     IP: 192.168.1.100
     Статус: НЕАКТИВНА
     Требуется физическое подключение
     
  🧠 Нейро-матрица (сознание д-ра Волкова)
     IP: 192.168.1.254
     Статус: АКТИВНА
     Интеграция: 100%
"""
	
	var local_label := Label.new()
	local_label.text = local_text
	local_label.size = Vector2(right_width - 100, right_height - 160)
	local_label.position = Vector2(10, 10)
	local_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	local_label.add_theme_font_size_override("font_size", 14)
	local_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	local_tab.add_child(local_label)
	
	# Вкладка 2: Внешняя сеть (недоступна)
	var external_tab := Control.new()
	external_tab.name = "Внешняя сеть"
	tab_container.add_child(external_tab)
	
	var ext_title := Label.new()
	ext_title.text = "⚠ ВНЕШНЯЯ СЕТЬ НЕДОСТУПНА"
	ext_title.size = Vector2(right_width - 100, 40)
	ext_title.position = Vector2(10, 30)
	ext_title.add_theme_font_size_override("font_size", 22)
	ext_title.add_theme_color_override("font_color", Color(1.0, 0.4, 0.2))
	external_tab.add_child(ext_title)
	
	var ext_text := """
Соединение с внешней сетью отсутствует.

Причина: Антенна связи на поверхности бункера 
неактивна. Требуется физическое подключение 
через робота-разведчика.

План действий:
  1. Подключиться к роботу NEXUS-R1
  2. Покинуть бункер через ворота
  3. Добраться до антенны на поверхности
  4. Активировать спутниковый модуль
  5. Установить связь с внешним миром

Статус антенны: ОЖИДАЕТ ПОДКЛЮЧЕНИЯ
Спутники на орбите: 12 доступно
Протокол связи: AES-256 зашифрован
"""
	
	var ext_label := Label.new()
	ext_label.text = ext_text
	ext_label.size = Vector2(right_width - 100, right_height - 200)
	ext_label.position = Vector2(10, 90)
	ext_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ext_label.add_theme_font_size_override("font_size", 15)
	ext_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	external_tab.add_child(ext_label)

# === МЕНЮ ПУСК ===
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
