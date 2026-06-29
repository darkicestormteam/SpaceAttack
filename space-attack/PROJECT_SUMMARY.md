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

## 2. Облачное сохранение (Яндекс SDK) — Стратегия: облако = истина

### Методы:
| save_game() | save_game_async() | save_game_cloud_now() | save_game_critical_async() | **force_save_to_cloud()** |

- **Интервал автосохранения:** 15 секунд (AUTO_CLOUD_INTERVAL)
- **Лимит API:** не чаще 10 секунд между вызовами set_data (MIN_CLOUD_INTERVAL)
- **force_save_to_cloud()** — игнорирует MIN_CLOUD_INTERVAL, для критических событий
- **save_game_critical_async()** — async версия с flush=true, возвращает bool
- **save_game_cloud_now()** — с учётом лимита

### Стратегия загрузки (`_load_from_cloud()`):
1. SaveManager ждёт инициализацию AdsManager
2. Читает локальный файл, извлекает флаг `_cloud_was_synced`
3. Загружает из облака
4. __Сценарий 1.__ Облако доступно + данные есть → облако главное, пишем в локал
5. __Сценарий 2.__ Облако доступно + пусто + `_cloud_was_synced == true` → был намеренный сброс (Clear Cloud Data) → дефолт и в облако, и в локал
6. __Сценарий 3a.__ Первый вход, есть локальные → отправляем локальные в облако
7. __Сценарий 3b.__ Первый вход, нет данных → дефолт → отправляем дефолты в облако
8. __Сценарий 4.__ Облако недоступно → офлайн-режим с локальным кешем

### IAP / Покупки:
- `can_purchase()` в AdsManager блокирует кнопки, если SDK/player/payments не готовы
- При возврате фокуса окна (`_on_game_api_resumed`) — перепроверка `can_purchase()`
- При `payments_init()` успешно — сигнал `purchase_availability_changed(true)`
- Офлайн-покупки физически невозможны (нет SDK → кнопка заблокирована)

### Флаг `_cloud_was_synced`:
- Хранится в локальном savegame.json как поле `_cloud_was_synced`
- Устанавливается в true при любом успешном сохранении в облако
- Сбрасывается при намеренном Clear Cloud Data
- Позволяет отличить "первый запуск" от "сброса облака"

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
