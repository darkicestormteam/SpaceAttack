# Памятка по интеграции Yandex рекламы в Godot игры

## 1. Где показывать рекламу (требования Яндекс.Игр п. 4.4)

**МОЖНО (логические паузы):**
- ✅ В главном меню при старте игры
- ✅ После смерти игрока (Game Over)
- ✅ После победы над финальным боссом
- ✅ При переходе между уровнями
- ✅ На загрузочных экранах

**НЕЛЬЗЯ:**
- ❌ Между волнами в реальном времени
- ❌ Автоматически посреди геймплея
- ❌ Пока игрок активен в бою
- ❌ Любой автоматический показ без явной логической паузы

---

## 2. Кулдаун — обязательно

Минимальный интервал между показами interstitial рекламы — **60 секунд**.

```gdscript
var _last_ad_time: float = -60.0

func can_show_interstitial() -> bool:
	var now = Time.get_ticks_msec() / 1000.0
	return now - _last_ad_time >= 60.0
```

После каждого показа запоминать время:
```gdscript
_last_ad_time = Time.get_ticks_msec() / 1000.0
```

---

## 3. Главная ловушка: сигналы + await

**Симптом:** игра зависает при первом же вызове рекламы.

**Причина:** если `signal.emit()` вызывается синхронно внутри функции, а `await` стоит после вызова этой функции, то `await` НИКОГДА не дождётся сигнала — он уже улетел.

```gdscript
# НЕПРАВИЛЬНО — зависнет!
manager.show_ad()    # внутри может быть emit()
await manager.ad_closed  # опоздал, сигнал уже был

# Внутри show_ad():
func show_ad():
	if not can_show():
		ad_closed.emit()  # синхронный emit — await не поймает
		return
```

**Решение — `call_deferred`:**
```gdscript
func show_ad():
	if not can_show():
		call_deferred("_emit_closed")  # отложить на следующий кадр
		return

func _emit_closed():
	ad_closed.emit()
```

---

## 4. Все методы YandexSDK — это корутины

`YandexSDK.leaderboard.init()`, `.set_score()`, `feedback.can_review()`, `feedback.request_review()` и т.д. — все они **асинхронные**. Без `await` они просто не выполняются, код идёт дальше как ни в чём не бывало.

**НЕПРАВИЛЬНО — счёт не отправится:**
```gdscript
YandexSDK.leaderboard.set_score("Leaderboard", score)  # без await — пропускается
```

**ПРАВИЛЬНО:**
```gdscript
await YandexSDK.leaderboard.set_score("Leaderboard", score)
```

**Но:** если сделать `await` до показа UI, экран не отобразится. Выход:
```gdscript
func show_game_over():
	# сначала реклама, показ UI
	show()
	# потом фоновый await — не блокирует игрока
	_submit_score()

func _submit_score():
	await YandexSDK.leaderboard.init()
	await YandexSDK.leaderboard.set_score("Leaderboard", score)
```

---

## 5. Пауза и реклама — кто кого

Реклама сама ставит паузу (сигнал `show_fullscreen_opened`) и сама снимает (`show_fullscreen_closed`). **Ничего не трогай в обработчиках SDK.**

Если ты ставишь паузу до рекламы (Game Over, Victory):
1. Ты: `get_tree().paused = true`
2. Реклама: `get_tree().paused = true` (повторно — без изменений)
3. Реклама закрылась: `get_tree().paused = false`
4. **Ты**: `get_tree().paused = true` — иначе игра продолжится в фоне!

```gdscript
# game_over.gd
func _show():
	get_tree().paused = true          # 1
	manager.show_ad()
	await manager.ad_closed
	get_tree().paused = true          # 4 — реклама сняла, возвращаем
	show()
```

---

## 6. Автозагрузки (синглтоны)

ScoreManager, GameManager и прочие автозагрузки НЕ пересоздаются при смене сцены. Если не сбросить счёт при старте новой игры, он останется от предыдущей сессии.

**ВСЕГДА сбрасывай данные в `_ready()` игровой сцены:**
```gdscript
func _ready():
	ScoreManager.reset_score()
```

---

## 7. Что должно быть в проекте обязательно (для модерации)

| Функция | Где | Зачем |
|---|---|---|
| `YandexSDK.game_ready()` | После инициализации SDK | Сообщить платформе, что игра загружена |
| `YandexSDK.gameplay_start()` | При старте боя/уровня | Показать платформе, что идёт геймплей |
| `YandexSDK.gameplay_stop()` | При Game Over, паузе, Victory | Показать платформе, что геймплей остановлен |
| `YandexSDK.leaderboard.init()` | Перед отправкой счёта | Инициализировать таблицу лидеров |
| `leaderboard.set_score()` | При Game Over / Victory | Отправить счёт |
| `feedback.can_review()` | После Victory | Запросить отзыв (если можно) |
| `feedback.request_review()` | После Victory | Показать окно отзыва |

---

## 8. Чек-лист перед отправкой на модерацию

- [ ] Реклама НЕ показывается во время геймплея
- [ ] Реклама показывается не чаще 1 раза в 60 секунд
- [ ] После закрытия рекламы игра НЕ зависает
- [ ] После закрытия рекламы игра НЕ продолжается в фоне
- [ ] Счёт сбрасывается при старте новой игры
- [ ] Счёт отправляется в лидерборд при Game Over / Victory
- [ ] game_ready() вызван после инициализации SDK
- [ ] gameplay_start/stop вызываются корректно
- [ ] `call_deferred` для всех быстрых `emit()` перед `await`
- [ ] Корутины SDK (`leaderboard`, `feedback`) вызываются с `await`
