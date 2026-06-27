# Полный список модулей с редкостью из .tres файлов

## Common (7 шт)

| ID | Файл | Название | Редкость из .tres |
|----|------|----------|-------------------|
| `laser` | `Laser_Common.tres` | Лазер | `"common"` |
| `shotgun` | `shotgun.tres` | Дробовик | *(поле отсутствует → дефолт "common")* |
| `rocket` | `rocket.tres` | Ракетница | `"common"` |
| `shield` | `shield_new.tres` | Энергощит | `"common"` |
| `turbo` | `turbo.tres` | Турбо-ускоритель | `"common"` *(в коде обрабатывается как common)* |
| `drone` | `drone.tres` | Дрон | `"common"` |
| `magnet` | `magnet.tres` | Магнит | `"common"` (не используется, задумка) |

## Rare (5 шт)

| ID | Файл | Название | Редкость из .tres |
|----|------|----------|-------------------|
| `laser_mk2` | `Laser_MkII.tres` | Двойной Лазер Mk.II | `"rare"` |
| `rocket_mk2` | `rocket_mk2.tres` | Ракетница Mk.II | `"rare"` |
| `composite_armor` | `composite_armor.tres` | Композитная броня | `"rare"` |
| `forsage` | `forsage.tres` | Форсаж | `"rare"` |
| `drone_rare` | `drone_rare.tres` | Дроны-близнецы | `"rare"` |

## Epic (8 шт)

| ID | Файл | Название | Редкость из .tres |
|----|------|----------|-------------------|
| `laser_pierce` | `Laser_Pierce.tres` | Пронзающий Лазер | `"epic"` |
| `rocket_homing` | `rocket_homing.tres` | Самонаводящийся Залп | `"epic"` |
| `diffusor` | `diffusor.tres` | Диффузор | `"epic"` |
| `tactical_accelerator` | `tactical_accelerator.tres` | Тактический ускоритель | `"epic"` |
| `drone_epic` | `drone_epic.tres` | Боевые дроны | `"epic"` |
| `shockwave` | `shockwave.tres` | Импульсная волна | `"epic"` |
| `nanobots` | `nanobots.tres` | Нано-роботы | `"epic"` |
| `shotgun_pressure` | `shotgun_pressure.tres` | Дробовик Пробивной | `"epic"` |

## Legendary (4 шт)

| ID | Файл | Название | Редкость из .tres |
|----|------|----------|-------------------|
| `laser_plasma` | `Laser_Plasma.tres` | Самонаводящаяся Плазма | `"legendary"` |
| `cocoon_shield` | `cocoon_shield.tres` | Кокон возрождения | `"legendary"` |
| `drone_legendary` | `drone_legendary.tres` | Эскадрилья | `"legendary"` |
| `shotgun_heavy` | `shotgun_heavy.tres` | Дробовик Картечь | `"legendary"` |

## Дополнительно — не в пуле сундука (или неактивны)

| ID | Файл | Редкость | Причина |
|----|------|----------|---------|
| `energy_shield` | `energy_shield.tres` | `"common "` (с пробелом) | Дубль `shield`/`shield_new`, не используется |
| `Laser_Rare` | `Laser_Rare.tres` | *(нет полей name/rarity)* | Задумка? Не используется |
| `magnet` | `magnet.tres` | common | Задумка, не реализован в коде |

---

## Фактическое распределение в сундуке модулей (MODULE_CHEST_POOL)

В сундуке сейчас 25 модулей с редкостью из .tres:

| Редкость | Кол-во | Модули |
|----------|--------|--------|
| **Common** | 5 | shotgun, rocket, shield, turbo, drone |
| **Rare** | 5 | laser_mk2, forsage, composite_armor, rocket_mk2, drone_rare |
| **Epic** | 8 | laser_pierce, rocket_homing, diffusor, tactical_accelerator, drone_epic, shockwave, nanobots, shotgun_pressure |
| **Legendary** | 4 | laser_plasma, cocoon_shield, drone_legendary, shotgun_heavy |

**Замечание:** `turbo.tres` имеет `rarity = "rare"`, но в коде Player.gd он обрабатывается в блоке utility как обычный модуль. По факту — по файлу он Rare, в игре ведёт как Common.