class_name MapValidator
extends RefCounted
# Проверяет MapLayout на геймплейные правила ДО сборки карты.
# Используется в тестовой сцене (PoC Фазы A), а в Фазе B станет ядром
# цикла ретраев генератора: сгенерировал layout -> validate -> если ошибки,
# перегенерировать по другому сиду; после N попыток — фолбэк на рукописную карту.

const ARENA_SIZE := Vector2(1920, 1080)   # базовое разрешение window/size
const MARGIN_SPAWN := 150.0               # спавн за краем арены (с запасом на спрайт)
const SLOT_CLEARANCE := 100.0             # слот не ближе этого к пути (не на дороге)
const SLOT_MAX_DIST := 240.0              # слот не дальше этого от пути (башня стреляет)
const SLOT_EDGE_MARGIN := 60.0            # слот не ближе этого к краю арены
const BAKE_INTERVAL := 20.0               # плотность bake'а пути (как у врага)


static func validate(layout: MapLayout) -> PackedStringArray:
	var errors := PackedStringArray()
	if layout.path_points.size() < 2:
		errors.append("Путь короче 2 точек — врагу некуда идти.")
		return errors

	var baked := _bake_path(layout.path_points)

	# 1. спавн за краем арены
	var spawn := layout.path_points[0]
	if _distance_point_to_rect(spawn, Rect2(Vector2.ZERO, ARENA_SIZE)) < MARGIN_SPAWN:
		errors.append("Спавн %s внутри/у края арены — должен быть за краем на >= %d." % [str(spawn), int(MARGIN_SPAWN)])

	# 2-4. слоты
	var inner := Rect2(Vector2(SLOT_EDGE_MARGIN, SLOT_EDGE_MARGIN),
		ARENA_SIZE - Vector2(SLOT_EDGE_MARGIN, SLOT_EDGE_MARGIN) * 2.0)
	for i in layout.tower_slot_positions.size():
		var slot := layout.tower_slot_positions[i]
		if not inner.has_point(slot):
			errors.append("Слот %d %s вне арены или у самого края." % [i + 1, str(slot)])
			continue
		var d := _min_distance_to_polyline(slot, baked)
		if d < SLOT_CLEARANCE:
			errors.append("Слот %d %s лежит на дороге (до пути %.0f < %.0f)." % [i + 1, str(slot), d, SLOT_CLEARANCE])
		elif d > SLOT_MAX_DIST:
			errors.append("Слот %d %s слишком далеко от пути (до пути %.0f > %.0f) — башня бесполезна." % [i + 1, str(slot), d, SLOT_MAX_DIST])

	return errors


# Curve2D из контрольных точек -> baked точки (тот же путь, что читает враг).
static func _bake_path(points: PackedVector2Array) -> PackedVector2Array:
	var curve := Curve2D.new()
	curve.bake_interval = BAKE_INTERVAL
	for p in points:
		curve.add_point(p)
	return curve.get_baked_points()


# 0 если точка внутри rect, иначе расстояние до ближайшего края.
static func _distance_point_to_rect(p: Vector2, rect: Rect2) -> float:
	var dx := maxf(rect.position.x - p.x, p.x - rect.end.x)
	var dy := maxf(rect.position.y - p.y, p.y - rect.end.y)
	if dx <= 0.0 and dy <= 0.0:
		return 0.0
	return Vector2(maxf(dx, 0.0), maxf(dy, 0.0)).length()


# Минимум от точки до всех baked-сегментов (перебор по baked точкам: bake плотный,
# интервал 20px, погрешность <=10px — для порогов 100/240 несущественна).
static func _min_distance_to_polyline(p: Vector2, pts: PackedVector2Array) -> float:
	var best := INF
	for i in pts.size():
		best = minf(best, p.distance_to(pts[i]))
	return best
