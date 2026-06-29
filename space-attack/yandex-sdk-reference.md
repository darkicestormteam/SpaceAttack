# Яндекс SDK — Справочник (данные игрока, облачные сохранения, IAP)

> Источник: документация Яндекс.Игр для разработчиков  
> Дата сохранения: 29.06.2026

---

## 1. Инициализация Player

```js
const ysdk = await YaGames.init();

try {
    const player = await ysdk.getPlayer();
} catch (e) {
    // Ошибка при инициализации объекта Player.
}
```

При инициализации передаются:
- Идентификатор пользователя — для всех
- Аватар и имя — для авторизованных игроков
- Данные о покупках на платформе — для игроков из РФ

### Подписанные данные (signed)

```js
const player = await ysdk.getPlayer({ signed: true });
// player.signature — две строки в base64: <подпись>.<данные профиля>
```

> ⚠️ Лимит: 20 запросов за 5 минут

---

## 2. Внутриигровые данные

### player.setData(data, flush)

Сохраняет данные пользователя. Макс. размер — **200 КБ**.

| Параметр | Тип | Описание |
|----------|-----|----------|
| `data` | object | Пары «ключ — значение» |
| `flush` | boolean | `true` — немедленная отправка, `false` — в очередь |

```js
await player.setData({ achievements: ['trophy1', 'trophy2'] }, false);
```

- При `flush: false` — результат показывает только валидность данных  
- `player.getData()` вернёт данные последнего `setData()`, даже если ещё не отправлены

> ⚠️ Лимит: **100 запросов за 5 минут**

### player.getData(keys)

Асинхронно возвращает внутриигровые данные.

| Параметр | Тип | Описание |
|----------|-----|----------|
| `keys` | Array\<string\> | Список ключей. Если отсутствует — все данные |

> ⚠️ Лимит: **100 запросов за 5 минут**

---

## 3. Численная статистика

### player.setStats(stats)

Для часто изменяемых числовых значений (баллы, опыт, валюта). Макс. размер — **10 КБ**.

```js
await player.setStats({ score: 15000, level: 5 });
```

### player.getStats(keys)

Асинхронно возвращает численные данные.

### player.incrementStats(increments)

Изменяет численные данные:
```js
const result = await player.incrementStats({ score: 10 });
```

> ⚠️ Лимит для всех методов stats: **60 запросов за 1 минуту**

---

## 4. Авторизация

### Проверка
```js
player.isAuthorized() // true | false
```

### Диалог авторизации
```js
await ysdk.auth.openAuthDialog();
```

> `player.getMode()` устарел!

---

## 5. Данные профиля

| Метод | Описание |
|-------|----------|
| `player.getUniqueID()` | Постоянный уникальный ID |
| `player.getIDsPerGame()` | ID во всех играх разработчика |
| `player.getName()` | Имя пользователя |
| `player.getPhoto(size)` | URL аватара (`small`, `medium`, `large`) |
| `player.getPayingStatus()` | `paying` / `partially_paying` / `not_paying` / `unknown` |

> `player.getID()` устарел

---

## 6. Сводка лимитов

| Метод | Лимит |
|-------|-------|
| `ysdk.getPlayer()` | 20 запросов за 5 минут |
| `player.setData()` | 100 запросов за 5 минут |
| `player.getData()` | 100 запросов за 5 минут |
| `player.setStats()` | 60 запросов за 1 минуту |
| `player.getStats()` | 60 запросов за 1 минуту |
| `player.incrementStats()` | 60 запросов за 1 минуту |

---

## 7. Проблемы

### Размер сохранений
- `setData` — до 200 КБ
- `setStats` — до 10 КБ
- Если больше — нужен свой сервер

### Сброс прогресса
```js
await player.setData({});   // очистить данные
await player.setStats({});  // очистить статистику
```

### Потеря прогресса на iOS
Используйте `safeStorage` вместо `localStorage`:
```js
const safeStorage = await ysdk.getStorage();
safeStorage.setItem('key', 'value');