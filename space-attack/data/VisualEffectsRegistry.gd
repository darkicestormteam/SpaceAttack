extends Resource

## Единый реестр всех визуальных конфигов для эффектов.
## Все конфиги создаются как статические Resource-объекты
## с fallback-значениями по умолчанию.

## Shockwave - импульсная волна
static func shockwave() -> Resource:
	var r = Resource.new()
	r.set_meta("outer_arc_color", Color(0.4, 0.8, 1.0, 0.9))
	r.set_meta("outer_arc_width", 0.04)
	r.set_meta("inner_arc_color", Color(0.6, 0.9, 1.0, 0.6))
	r.set_meta("inner_arc_width", 0.03)
	r.set_meta("fill_color", Color(0.3, 0.7, 1.0, 0.18))
	r.set_meta("duration", 0.2)
	r.set_meta("max_radius", 200.0)
	r.set_meta("damage", 20)
	return r

## Shield — энергетический щит (визуал вокруг корабля)
static func shield() -> Resource:
	var r = Resource.new()
	r.set_meta("arc_color", Color(0.2, 0.4, 1, 0.35))
	r.set_meta("arc_radius", 36.0)
	r.set_meta("arc_width", 3.0)
	r.set_meta("arc_segments", 48)
	r.set_meta("fill_color", Color(0.1, 0.3, 1, 0.08))
	r.set_meta("fill_radius", 32.0)
	return r

## Shield Flash — зелёная вспышка (обычный щит)
static func shield_flash() -> Resource:
	var r = Resource.new()
	r.set_meta("flash_color", Color(0.2, 1.0, 0.4))
	r.set_meta("max_radius", 48.0)
	r.set_meta("duration", 0.2)
	r.set_meta("line_width", 4.0)
	r.set_meta("fill_alpha", 0.25)
	return r

## Shield Flash Composite — жёлтая вспышка (Composite Armor)
static func shield_flash_composite() -> Resource:
	var r = Resource.new()
	r.set_meta("flash_color", Color(1.0, 0.8, 0.2))
	r.set_meta("max_radius", 48.0)
	r.set_meta("duration", 0.2)
	r.set_meta("line_width", 4.0)
	r.set_meta("fill_alpha", 0.25)
	return r

## Shield Flash Cocoon — фиолетовая вспышка (Cocoon Shield)
static func shield_flash_cocoon() -> Resource:
	var r = Resource.new()
	r.set_meta("flash_color", Color(0.8, 0.2, 1.0))
	r.set_meta("max_radius", 48.0)
	r.set_meta("duration", 0.3)
	r.set_meta("line_width", 4.0)
	r.set_meta("fill_alpha", 0.25)
	return r

## Reactive Blast — оранжевая вспышка (Diffusor)
static func reactive_blast() -> Resource:
	var r = Resource.new()
	r.set_meta("arc_color", Color(1, 0.6, 0.2, 0.8))
	r.set_meta("arc_radius", 40.0)
	r.set_meta("arc_width", 2.0)
	r.set_meta("fill_color", Color(1, 0.4, 0.1, 0.15))
	r.set_meta("fill_radius_mult", 0.5)
	r.set_meta("duration", 0.15)
	r.set_meta("final_scale", 3.0)
	return r

## Heal Flash — зелёная вспышка лечения (Nanobots)
static func heal_flash() -> Resource:
	var r = Resource.new()
	r.set_meta("flash_color", Color(0.1, 1, 0.3, 0.5))
	r.set_meta("arc_color", Color(0.3, 1, 0.5, 0.7))
	r.set_meta("flash_radius", 20.0)
	r.set_meta("arc_radius", 24.0)
	r.set_meta("arc_width", 1.5)
	r.set_meta("duration", 0.3)
	return r

## Heal Flash Pickup — яркая вспышка (Health Pack)
static func heal_flash_pickup() -> Resource:
	var r = Resource.new()
	r.set_meta("flash_color", Color(0.2, 1.0, 0.5, 0.7))
	r.set_meta("arc_color", Color(0.4, 1.0, 0.6, 0.9))
	r.set_meta("flash_radius", 24.0)
	r.set_meta("arc_radius", 28.0)
	r.set_meta("arc_width", 2.0)
	r.set_meta("duration", 0.4)
	return r
