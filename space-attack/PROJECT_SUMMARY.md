# SpaceAttack — Итоговый отчёт (29.06.2026), окончание контекста

## Статус: игра прошла 2 этап модерации Яндекс.Игр

## 1. Реклама

### Interstitial:
- При загрузке Hangar, при выборе сложности, при отказе от удвоения

### Rewarded Video:
- **Удвоение кредитов** — при выходе в Hangar
- **Воскрешение** — 1 раз за забег, после rewarded рекламы + обратный отсчёт 3-2-1

### Исправление бага rewarded:
- Сигнал `rewarded_video_rewarded` от Яндекс SDK приходит ПОСЛЕ `rewarded_video_closed`
- Исправлено: корневой сигнал `ad_flow_finished` + CONNECT_ONE_SHOT

## 2. Облачное сохранение (Яндекс SDK)

### Методы:
| save_game() | save_game_async() | save_game_cloud_now() | save_game_critical_async() |

- Буферизация: не чаще 1 раза в 6 секунд
- IAP с flush=true и `await`
- `save_game_critical_async()` возвращает bool

### Загрузка при старте:
1. SaveManager ждёт инициализацию AdsManager
2. Читает локальный файл **без применения** (через `_load_local_raw_data()`)
3. Загружает из облака
4. Сравнивает `last_saved_at`: выбирает самые свежие данные
5. Если облачные данные новее → применяем облачные + сохраняем локально (`save_game_async()`)
6. Если локальные данные новее или облако пусто → применяем локальные + **немедленно отправляем в облако** (`await _save_to_cloud_impl(true)`)
7. Если данных нет нигде → дефолт + **немедленно отправляем дефолты в облако**

### Важно для следующего чата:
- В `_get_save_data()` и `_to_dict()` добавлено поле `last_saved_at`
- В `_load_from_cloud()` теперь НЕ сбрасывает локальные данные, если облако пусто
- Есть `_load_local_raw_data()` — читает файл не применяя

## 3. GameplayAPI

- Привязан к GameManager.set_state()
- BATTLE → gameplay_start(), MENU/GAME_OVER/PAUSED → gameplay_stop()

## 4. Единая PauseMenu

- 3 режима: PAUSED, GAME_OVER, VICTORY
- Заменяет GameOver. И VictoryScreen.
- Параметр `can_revive` для кнопки воскрешения

## 5. Система банка кредитов

- Кредиты копятся в `session_credits_bank`
- Начисляются только в Hangar
- DoubleCreditsAnimation (Tween + кнопка "Принять")

## 6. Последние изменения (конец сессии)

- **last_saved_at** — добавлена метка времени для сравнения свежести данных
- **`_load_from_cloud()`** — полностью переписан: читает локальный файл без применения, сравнивает с облаком, выбирает новейшие
- **Немедленная отправка в облако** — вместо `_mark_cloud_pending()` (задержка 6с) теперь `await _save_to_cloud_impl(true)` при старте, чтобы прогресс не терялся при быстром закрытии игры
- **`_load_local_raw_data()`** — новый метод для чтения файла без побочных эффектов
- **IAP облачное сохранение** — теперь работает (player init + flush=true + await)
- **set_defaults()** — сбрасывает абсолютно все поля

## 7. Что не работает:
- **Сброс прогресса через Clear Cloud Data** — больше не сбрасывает (облако пусто → оставляем локальные)
- Для сброса нужно добавить кнопку в UI или удалять IndexedDB вручную

## 8. Файлы для следующей сессии:

| Файл | Что делать |
|------|-----------|
| `SaveManager.gd` | Проверить `_load_from_cloud()`, `_load_local_raw_data()`, `last_saved_at` |
| `AdsManager.gd` | IAP сохранение с проверкой результата |
| `Main.gd` | Воскрешение, save_game_cloud_now при переходах |
| `Hangar.gd` | DoubleCreditsPopup, UI скрытие |
| `PauseMenu.gd` | can_revive, hide_menu(release_pause) |

## 9. Новые файлы:
- `ReviveCountdown.tscn/.gd` — обратный отсчёт 3-2-1
- `DoubleCreditsAnimation.tscn/.gd` — анимация начисления кредитов
