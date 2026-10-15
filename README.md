# Проект Берёзов

Godot 4.7 — минимальный 3D-проект с основной сценой и персонажем с управлением и падением.

Инструкции:
1. Клонируйте репозиторий:
   git clone https://github.com/bmv1986/project-berezov.git
2. Откройте проект в Godot 4.7: File → Open Folder → выберите папку проекта (где лежит project.godot).
3. В Project → Project Settings → Input Map добавьте действия (см. ниже) или используйте GUI в настройках проекта.
4. Для работы с git на локальной машине: см. раздел "Работа локально".

Input Map (рекомендуемые действия):
- move_forward — W
- move_back — S
- move_left — A
- move_right — D
- jump — Space

Работа локально

1. Убедитесь, что у вас установлен Git и Godot 4.7.
2. Клонируйте репозиторий:
   git clone https://github.com/bmv1986/project-berezov.git
3. Перейдите в каталог проекта и откройте его в Godot 4.7:
   cd project-berezov
   godot         # или откройте Godot и выберите папку проекта
4. Вносите изменения в сцену и скрипты, затем коммитьте и пушьте:
   git add .
   git commit -m "Your message"
   git push origin main

Примечания
- Папка .import/ игнорируется — Godot генерирует её локально.
- Если хотите, могу добавить файл с настройками Input Map, но проще настроить через GUI в редакторе.
