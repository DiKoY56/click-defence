class_name MapGenerator
extends RefCounted
# Генерирует путь (монотонный X) и слоты. Финиш пути — прямой участок, входящий
# в ларёк под 90° к его левой грани, на уровне низа ларька.
# Геометрические предикаты — из MapValidator (единый источник истины).

const ARENA_SIZE := Vector2(1920, 1080)
const MARGIN_SPAWN := 150.0
const V_PAD := 120.0
const H_PAD_END := 120.0
const MIN_SEGMENT := 220.0
const AMP := 380.0
const PULL_TO_CENTER := 0.30
const POINTS_MIN := 5
const POINTS_MAX := 8
const BASE_HALF := 128.0        # полуширина/полувсота ларька (арт 128 * 2 / 2)
const ENTRY_INSET := 20.0       # насколько вход выше нижней кромки ларька
const APPROACH_LEN := 200.0     # длина прямого участка перед входом (перпендикуляр)

# --- слоты ---
const SLOT_COUNT_MIN := 5
const SLOT_COUNT_MAX := 7
const SLOT_HALF := 64.0
const SLOT_GAP := 28.0
const BASE_CLEAR := 120.0
const NEAR_MIN := 160.0
const NEAR_MAX := 220.0
const FAR_MIN := 260.0
const FAR_MAX := 380.0
const FAR_PROB := 0.4
const TRIES_PER_SLOT := 18
const GUARANTEE_TRIES := 30
const PATH_T_LO := 0.12
const PATH_T_HI := 0.88


static func generate_path(rng: RandomNumberGenerator, base_pos: Vector2) -> PackedVector2Array:
	var center_y := ARENA_SIZE.y * 0.5
	var start := Vector2(
		-(MARGIN_SPAWN + rng.randf_range(0.0, 80.0)),
		rng.randf_range(V_PAD, ARENA_SIZE.y - V_PAD)
	)
	# Вход: у НИЗА левой грани ларька.
	var entry := Vector2(base_pos.x - H_PAD_END, base_pos.y + BASE_HALF - ENTRY_INSET)
	# Разворот: строго слева от входа на ТОЙ ЖЕ Y => последний отрезок горизонтален,
	# то есть перпендикулярен вертикальной грани ларька (вход под 90°).
	var approach := Vector2(entry.x - APPROACH_LEN, entry.y)

	# Змейку строим до точки разворота, а не до самого входа.
	var k := rng.randi_range(POINTS_MIN, POINTS_MAX)
	var xs := _split_horizontal(start.x, approach.x, k, rng)

	var pts := PackedVector2Array()
	pts.append(start)
	var prev := start
	for i in range(xs.size()):
		var y := lerpf(prev.y, center_y, PULL_TO_CENTER) + rng.randf_range(-AMP, AMP)
		y = clampf(y, V_PAD, ARENA_SIZE.y - V_PAD)
		var p := Vector2(xs[i], y)
		pts.append(p)
		prev = p
	pts.append(approach)   # выход на прямую
	pts.append(entry)      # вход в ларёк под прямым углом
	return pts


static func generate_slots(layout: MapLayout, rng: RandomNumberGenerator) -> PackedVector2Array:
	var baked := MapValidator._bake_path(layout.path_points)
	if baked.size() < 3:
		return PackedVector2Array()

	var n := rng.randi_range(SLOT_COUNT_MIN, SLOT_COUNT_MAX)
	var inner := Rect2(
		Vector2(MapValidator.SLOT_EDGE_MARGIN, MapValidator.SLOT_EDGE_MARGIN),
		ARENA_SIZE - Vector2(MapValidator.SLOT_EDGE_MARGIN, MapValidator.SLOT_EDGE_MARGIN) * 2.0
	)
	var lo := int(baked.size() * PATH_T_LO)
	var hi := int(baked.size() * PATH_T_HI)
	if hi - lo < 2:
		lo = 1
		hi = baked.size() - 1

	var slots: Array[Vector2] = []
	var attempts := 0
	var max_attempts := n * TRIES_PER_SLOT
	while slots.size() < n and attempts < max_attempts:
		attempts += 1
		var i := rng.randi_range(lo, hi - 1)
		var cand := _perpendicular_candidate(baked, i, rng)
		if not _passes_slot_filters(cand, baked, slots, layout, inner):
			continue
		slots.append(cand)

	if _count_far(slots, baked) == 0 and slots.size() < SLOT_COUNT_MAX + 1:
		var g := 0
		while g < GUARANTEE_TRIES:
			g += 1
			var i := rng.randi_range(lo, hi - 1)
			var cand := _perpendicular_candidate(baked, i, rng, true)
			if not _passes_slot_filters(cand, baked, slots, layout, inner):
				continue
			slots.append(cand)
			break

	return PackedVector2Array(slots)


static func _passes_slot_filters(cand: Vector2, baked: PackedVector2Array, slots: Array[Vector2], layout: MapLayout, inner: Rect2) -> bool:
	if not inner.has_point(cand):
		return false
	if cand.distance_to(layout.base_position) < BASE_CLEAR:
		return false
	for s in slots:
		if MapValidator._aabb_gap(cand, s, SLOT_HALF) < SLOT_GAP:
			return false
	var d := MapValidator._min_distance_to_polyline(cand, baked)
	if d < MapValidator.SLOT_CLEARANCE or d > MapValidator.SLOT_FAR_DIST:
		return false
	return true


static func _count_far(slots: Array[Vector2], baked: PackedVector2Array) -> int:
	var c := 0
	for s in slots:
		if MapValidator._min_distance_to_polyline(s, baked) > MapValidator.SLOT_NEAR_DIST:
			c += 1
	return c


static func _perpendicular_candidate(baked: PackedVector2Array, i: int, rng: RandomNumberGenerator, force_far: bool = false) -> Vector2:
	var a := baked[maxi(i - 1, 0)]
	var b := baked[mini(i + 1, baked.size() - 1)]
	var dir := b - a
	if dir.length() < 0.001:
		return baked[i]
	dir = dir.normalized()
	var normal := Vector2(-dir.y, dir.x)
	var side := 1.0 if rng.randf() < 0.5 else -1.0
	var far := force_far or rng.randf() < FAR_PROB
	var d := rng.randf_range(FAR_MIN, FAR_MAX) if far else rng.randf_range(NEAR_MIN, NEAR_MAX)
	return baked[i] + normal * side * d


static func _split_horizontal(x0: float, x1: float, k: int, rng: RandomNumberGenerator) -> Array[float]:
	var total := x1 - x0
	var free := total - MIN_SEGMENT * float(k + 1)
	while free < 0.0 and k > 2:
		k -= 1
		free = total - MIN_SEGMENT * float(k + 1)

	var bonuses: Array[float] = []
	var sum_b := 0.0
	for i in range(k + 1):
		var b := rng.randf()
		bonuses.append(b)
		sum_b += b

	var xs: Array[float] = []
	var acc := x0
	if sum_b <= 0.0:
		var step := total / float(k + 1)
		for i in range(k):
			acc += step
			xs.append(acc)
		return xs
	for i in range(k):
		acc += MIN_SEGMENT + bonuses[i] / sum_b * free
		xs.append(acc)
	return xs
