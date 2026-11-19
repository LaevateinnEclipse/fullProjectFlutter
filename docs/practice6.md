# Практическая работа 6 — сайт группы Ghost

Репозиторий: https://github.com/LaevateinnEclipse/fullProjectFlutter

Тема не менялась: дискография, состав, мерч и афиша. Практика 6 добавляет адаптивные экраны, релизную сборку, тесты и публикацию.

## Адаптив

- 360 px: одна колонка, нижняя навигация, карточки записей, фильтры свёрнуты.
- 768 px: боковая навигация без подписей, карточки, на главной две колонки карточек разделов.
- 1280 px: таблицы с прокруткой по двум осям и боковая навигация с подписями.
- 1920 px: рабочая область не шире 1440 px, формы не шире 760 px.
- Длинные названия обрезаются. Состояние списка сохраняется при изменении ширины окна.
- До первого кадра видны название GHOST, индикатор и сообщение. Если загрузка не удалась, есть повтор.
- Разделы фаната, менеджера и администратора подгружаются через `deferred as`.

## Сборка и локальный запуск

```powershell
flutter pub get
flutter build web --release --no-web-resources-cdn --dart-define=API_BASE_URL=/api
node scripts/optimize-web.js build/web
$env:STATIC_DIR = (Resolve-Path build/web).Path
node server/mock-server.js --port 8080
```

Открыть `http://localhost:8080`. Клиент и API работают с одного адреса.
Адрес API задаётся при сборке. Для отладки отдельно от сервера:

```powershell
node server/mock-server.js --port 8080 --origin http://localhost:5555
flutter run -d chrome --web-port=5555 --dart-define=API_BASE_URL=http://localhost:8080/api
```

WebAssembly и запасной JavaScript:

```powershell
flutter build web --release --wasm --no-web-resources-cdn --dart-define=API_BASE_URL=/api
```

Сравнение размера: `node scripts/measure-web.js build/web`.

## Результаты сборки 19 ноября 2026 года

`flutter test` — 33 теста прошли. `flutter analyze` — без замечаний.
`node server/test-roles.js` и `node --test server/static-files.test.js` прошли.

| Вариант | Файлы без gzip-копий, МБ | Сумма gzip, МБ |
|---|---:|---:|
| Обычный релиз до удаления лишних ресурсов | 42,544 | 14,291 |
| Релиз с `--wasm` и JavaScript fallback | 45,213 | 15,281 |
| Оптимизированный обычный релиз | 25,025 | 9,163 |

1 МБ = 1 000 000 байт. Обычный релиз уменьшен на 41,18%.
Удалены 17 518 744 байт неиспользуемого skwasm и отладочных символов.
Подробные значения: `docs/pr6/verification`.
Время первой загрузки в этой таблице не измерялось автоматически: его нужно снять в браузере до события `flutter-first-frame` на экране входа.

Учебные учётки: `fan / fan123`, `ghoul / ghoul123`, `manager / manager123`, `admin / admin123`.

## Публикация

`Dockerfile` собирает Flutter, затем оставляет веб-релиз и Node API.
`render.yaml` описывает бесплатный Web Service. Один HTTPS-адрес отдаёт и страницы, и `/api`, поэтому нет смешанного HTTP/HTTPS и отдельного CORS между клиентом и API.
`PORT` задаёт хостинг. Секрет подписи токенов берётся из `JWT_SECRET`. В коде постоянного ключа нет.
Сервер отдаёт `index.html` для `/albums/12`, `/concerts/new` и других маршрутов Flutter. Отсутствующий JS-файл возвращает 404.

Автопроверки: `.github/workflows/verify.yml`.

На бесплатном Render файлы временные: после перезапуска записи возвращаются к демонстрационным. СУБД не подключается.

## Тесты

`test/practice6_test.dart` — восемь модульных проверок: пустое название, непустое название, год, почта, неполный JSON, числа из строки, ограничения менеджера, билеты фаната.

`test/practice6_widget_test.dart` — загрузка, пустой список, ошибка с повтором, валидация входа, скрытие кнопки создания для фаната, четыре ширины без потери выделения.

```powershell
flutter test
flutter analyze
dart format --output=none --set-exit-if-changed lib test
node server/test-roles.js
node --test server/static-files.test.js
```

## Что остаётся сделать вручную

Опубликовать сервис на Render (нужен аккаунт) и вставить рабочую ссылку в отчёт.
Снять экраны основных страниц на 360, 768, 1280 и 1920 px.
Вставить в отчёт вывод `flutter test`, `flutter analyze` и таблицу размеров обычной сборки, сборки `--wasm` и сборки после `scripts/optimize-web.js`.
