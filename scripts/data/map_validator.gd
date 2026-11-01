class_name MapValidator
extends RefCounted
# Проверяет MapLayout на геймплейные правила ДО сборки карты.
# validate() = validate_path() + validate_slots(); вызывается генератором в цикле
# ретраев (Фаза B/C) и в тестовых сценах. Битый layout не строится.

const ARENA_SIZE := Vector2(1920, 1080)
const MARGIN_SPAWN := 150.0
const SLOT_CLEARANCE := 100.0     # слот не ближе этого к пути (не на дороге)
const SLOT_NEAR_DIST := 240.0     # универсальный слот (любая башня достаёт)
const SLOT_FAR_DIST := 400.0      # максимально достижимый (радиус снайпера)
const SLOT_EDGE_MARGIN := 60.0
const PATH_LEN_MIN := 2400.0      # балансировочный диапазон длины пути
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

	# спавн за краем арены
	var spawn := pts[0]
	if _distance_point_to_rect(spawn, Rect2(Vector2.ZERO, ARENA_SIZE)) < MARGIN_SPAWN:
		errors.append("Спавн %s внутри/у края арены — должен быть за краем на >= %d." % [str(spawn), int(MARGIN_SPAWN)])

	# монотонный X (гарантия без самопересечений и продвижения) + промежуточные в окне
	for i in range(1, pts.size()):
		if pts[i].x <= pts[i - 1].x:
			errors.append("Путь не монотонен по X на точке %d (%s -> %s) — возможна петля/самопересечение." % [i, str(pts[i - 1]), str(pts[i])])
			break
	for i in range(1, pts.size() - 1):
		if pts[i].y < 0.0 or pts[i].y > ARENA_SIZE.y:
			errors.append("Промежуточная точка %d %s вне вертикального окна арены." % [i, str(pts[i])])

	# длина по bake'у (та же кривая, что читает враг)
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
		return errors   # без пути расстояние не измерить
	var baked := _bake_path(layout.path_points)
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
		elif d > SLOT_FAR_DIST:
			errors.append("Слот %d %s бесполезен даже для снайпера (до пути %.0f > %.0f)." % [i + 1, str(slot), d, SLOT_FAR_DIST])
		# NOTE: SLOT_NEAR_DIST не ошибка — это метка «универсальный»; различение near/far
		# использует генератор слотов (Фаза C) и подсветка в UI, валидатор лишь не отвергает far.
	return errors


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
