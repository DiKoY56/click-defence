class_name MapValidator
extends RefCounted
# Проверяет MapLayout на геймплейные правила ДО сборки карты.
# validate() = validate_path() + validate_slots(); вызывается генератором в цикле
# ретраев и в тестовых сценах. Битый layout не строится.
# ВСЕ геометрические предикаты (_bake_path, _min_distance_to_polyline, _aabb_gap)
# живут здесь и вызываются генератором из этого же места — единый источник истины,
# иначе цикл generate->validate->retry рассинхронится.

const ARENA_SIZE := Vector2(1920, 1080)
const MARGIN_SPAWN := 150.0
const SLOT_CLEARANCE := 160.0     # слот не ближе этого к пути (не на дороге)
const SLOT_NEAR_DIST := 240.0     # граница класса near/far (радиус бабушки)
const SLOT_FAR_DIST := 400.0      # максимально достижимый (радиус снайпера)
const SLOT_EDGE_MARGIN := 60.0
const SLOT_HALF := 64.0           # полуширина спрайта слота (арт 64 * scale 2 / 2)
const SLOT_GAP := 28.0            # мин. зазор МЕЖДУ КРАЯМИ слотов (не центрами!)
const BASE_CLEAR := 120.0         # слот-база не ближе (не влипает в ларёк)
const PATH_LEN_MIN := 2400.0
const PATH_LEN_MAX := 4000.0
const BAKE_INTERVAL := 20.0


static func validate(layout: MapLayout) -> PackedStringArray:
	var errors := validate_path(layout)
	errors.append_array(validate_slots(layout))
	return errors


static func validate_path(layout: MapLayout) -> PackedStringArray:
	var errors := PackedStringArray()
	var pts := layout.path_points
	if pts.size() < 2:
		errors.append("Путь короче 2 точек — врагу некуда идти.")
		return errors

	var spawn := pts[0]
	if _distance_point_to_rect(spawn, Rect2(Vector2.ZERO, ARENA_SIZE)) < MARGIN_SPAWN:
		errors.append("Спавн %s внутри/у края арены — должен быть за краем на >= %d." % [str(spawn), int(MARGIN_SPAWN)])

	for i in range(1, pts.size()):
		if pts[i].x <= pts[i - 1].x:
			errors.append("Путь не монотонен по X на точке %d (%s -> %s) — возможна петля/самопересечение." % [i, str(pts[i - 1]), str(pts[i])])
			break
	for i in range(1, pts.size() - 1):
		if pts[i].y < 0.0 or pts[i].y > ARENA_SIZE.y:
			errors.append("Промежуточная точка %d %s вне вертикального окна арены." % [i, str(pts[i])])

	# Вход в базу под прямым углом: последний отрезок строго осевой
	# (горизонталь -> перпендикуляр вертикальной грани, вертикаль -> горизонтальной).
	var last := pts[pts.size() - 1]
	var prev := pts[pts.size() - 2]
	var dx := absf(last.x - prev.x)
	var dy := absf(last.y - prev.y)
	if dx > 0.5 and dy > 0.5:
		errors.append("Тропа входит в базу не под прямым углом (dx=%.0f, dy=%.0f)." % [dx, dy])

	var baked := _bake_path(pts)
	var length := _polyline_length(baked)
	if length < PATH_LEN_MIN:
		errors.append("Путь слишком короткий (%.0f < %.0f) — враг добежит до базы слишком быстро." % [length, PATH_LEN_MIN])
	elif length > PATH_LEN_MAX:
		errors.append("Путь слишком длинный (%.0f > %.0f) — бой затянется." % [length, PATH_LEN_MAX])

	return errors


static func validate_slots(layout: MapLayout) -> PackedStringArray:
	var errors := PackedStringArray()
	if layout.path_points.size() < 2:
		return errors
	var baked := _bake_path(layout.path_points)
	var inner := Rect2(Vector2(SLOT_EDGE_MARGIN, SLOT_EDGE_MARGIN),
		ARENA_SIZE - Vector2(SLOT_EDGE_MARGIN, SLOT_EDGE_MARGIN) * 2.0)
	var slots := layout.tower_slot_positions
	for i in slots.size():
		var slot := slots[i]
		if not inner.has_point(slot):
			errors.append("Слот %d %s вне арены или у самого края." % [i + 1, str(slot)])
			continue
		var d := _min_distance_to_polyline(slot, baked)
		if d < SLOT_CLEARANCE:
			errors.append("Слот %d %s лежит на дороге (до пути %.0f < %.0f)." % [i + 1, str(slot), d, SLOT_CLEARANCE])
		elif d > SLOT_FAR_DIST:
			errors.append("Слот %d %s бесполезен даже для снайпера (до пути %.0f > %.0f)." % [i + 1, str(slot), d, SLOT_FAR_DIST])
		if slot.distance_to(layout.base_position) < BASE_CLEAR:
			errors.append("Слот %d %s влип в базу (до базы %.0f < %.0f)." % [i + 1, str(slot), slot.distance_to(layout.base_position), BASE_CLEAR])
		# слот-слот: зазор МЕЖДУ КРАЯМИ AABB, а не расстояние центров.
		# (Расстояние центров не видит диагональное сближение квадратных спрайтов.)
		for j in range(i + 1, slots.size()):
			var gap := _aabb_gap(slot, slots[j], SLOT_HALF)
			if gap < SLOT_GAP:
				errors.append("Слоты %d и %d слиплись (зазор краёв %.0f < %.0f)." % [i + 1, j + 1, gap, SLOT_GAP])
	return errors


# Зазор между краями двух axis-aligned квадратов с полушириной half.
# 0 если пересекаются; иначе расстояние между ближайшими точками (гранями/углами).
static func _aabb_gap(a: Vector2, b: Vector2, half: float) -> float:
	var gx := maxf(0.0, absf(a.x - b.x) - 2.0 * half)
	var gy := maxf(0.0, absf(a.y - b.y) - 2.0 * half)
	return Vector2(gx, gy).length()


static func _bake_path(points: PackedVector2Array) -> PackedVector2Array:
	var curve := Curve2D.new()
	curve.bake_interval = BAKE_INTERVAL
	for p in points:
		curve.add_point(p)
	return curve.get_baked_points()


static func _polyline_length(pts: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, pts.size()):
		total += pts[i].distance_to(pts[i - 1])
	return total


static func _distance_point_to_rect(p: Vector2, rect: Rect2) -> float:
	var dx := maxf(rect.position.x - p.x, p.x - rect.end.x)
	var dy := maxf(rect.position.y - p.y, p.y - rect.end.y)
	if dx <= 0.0 and dy <= 0.0:
		return 0.0
	return Vector2(maxf(dx, 0.0), maxf(dy, 0.0)).length()


static func _min_distance_to_polyline(p: Vector2, pts: PackedVector2Array) -> float:
	var best := INF
	for i in pts.size():
		best = minf(best, p.distance_to(pts[i]))
	return best
