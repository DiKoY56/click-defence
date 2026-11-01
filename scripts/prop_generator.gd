class_name PropGenerator
extends RefCounted
# Авторасстановка пропсов парка с ЗОНИРОВАНИЕМ по role:
#   придорожные роли (bench/lamp) — вдоль аллеи, по перпендикулярам к пути
#     на дистанции [ROAD_MIN..ROAD_MAX];
#   полевые роли (tree/decor) — в глубине, по джиттер-сетке с запретом
#     близости к пути (dist >= OPEN_MIN).
# Наложение на слоты/базу/другие пропсы режется AABB-ЗАЗОРОМ МЕЖДУ КРАЯМИ
# прямоугольников (не центрами): пропс anchored по ножке, тело уходит вверх на
# body_height и в стороны на clearance_radius — расстояние центров это не видит.
# Геометрию пути/слотов берёт из MapValidator (единый источник истины).
# Чисто от rng: тот же сид -> тот же декор.

const CELL := 150.0
const JITTER := 42.0
const DENSITY := 0.5
const MAX_PROPS := 30
const FOOT_MARGIN := 40.0
const PROP_PATH_CLEAR := 70.0
const PROP_GAP := 14.0
const PROP_SLOT_GAP := 16.0
const PROP_BASE_GAP := 12.0
const SLOT_HALF := 64.0
const BASE_HALF := 128.0

const ROLES_ROADSIDE: Array[StringName] = [&"bench", &"lamp"]
const ROAD_MIN := 120.0
const ROAD_MAX := 200.0
const ROAD_STEP := 140.0
const ROAD_PROB := 0.55

const OPEN_MIN := 260.0

const MIN_TREES := 3
const MIN_LAMPS := 1
const GUARANTEE_TRIES := 60       # ↑ с 40: строгий проход должен успеть найти пятно
const POOL_DIR := "res://assets/data"


static func load_pool() -> Array[PropData]:
	var pool: Array[PropData] = []
	var dir := DirAccess.open(POOL_DIR)
	if dir == null:
		return pool
	for f in dir.get_files():
		if f.begins_with("prop_") and f.ends_with(".tres"):
			var res: PropData = load(POOL_DIR.path_join(f)) as PropData
			if res != null:
				pool.append(res)
	return pool


static func generate_props(layout: MapLayout, rng: RandomNumberGenerator) -> Array[Prop]:
	var pool := load_pool()
	if pool.is_empty():
		push_warning("PropGenerator: пул prop_*.tres пуст — декор не расставлен.")
		return []

	var baked := MapValidator._bake_path(layout.path_points)
	if baked.size() < 3:
		return []

	var roadside_pool := _pool_by_roles(pool, ROLES_ROADSIDE)
	var field_pool := _pool_complement(pool, ROLES_ROADSIDE)

	var placed: Array[Prop] = []
	_scatter_field(field_pool, placed, baked, layout, rng)
	_scatter_roadside(roadside_pool, placed, baked, layout, rng)

	_ensure_role(placed, field_pool, rng, baked, layout, &"tree", MIN_TREES, true)
	_ensure_role(placed, roadside_pool, rng, baked, layout, &"lamp", MIN_LAMPS, false)
	return placed


static func _scatter_field(pool: Array[PropData], placed: Array[Prop], baked: PackedVector2Array, layout: MapLayout, rng: RandomNumberGenerator) -> void:
	if pool.is_empty():
		return
	var arena := MapValidator.ARENA_SIZE
	var cols := ceili(arena.x / CELL)
	var rows := ceili(arena.y / CELL)
	var cells := PackedVector2Array()
	for cy in rows:
		for cx in cols:
			cells.append(Vector2((cx + 0.5) * CELL, (cy + 0.5) * CELL))
	_fisher_yates(cells, rng)
	for center in cells:
		if placed.size() >= MAX_PROPS:
			break
		if rng.randf() > DENSITY:
			continue
		var data := _weighted_pick(pool, rng)
		var pos := center + Vector2(rng.randf_range(-JITTER, JITTER), rng.randf_range(-JITTER, JITTER))
		if not _passes_keepout(pos, data, baked, placed, layout, OPEN_MIN, INF, true):
			continue
		placed.append(_make_prop(pos, data))


# Инкремент i — В КОНЦЕ тела (см. фикс off-by-one): условие while защищает старое i,
# а _roadside_candidate читает baked[i+1]. Верхняя граница size-2 гарантирует, что
# и i-1>=0, и i+1<=size-1 валидны внутри хелпера.
static func _scatter_roadside(pool: Array[PropData], placed: Array[Prop], baked: PackedVector2Array, layout: MapLayout, rng: RandomNumberGenerator) -> void:
	if pool.is_empty() or baked.size() < 3:
		return
	var step_idx := maxi(int(ROAD_STEP / MapValidator.BAKE_INTERVAL), 1)
	var last_valid := baked.size() - 2
	var i := step_idx
	while i <= last_valid:
		if placed.size() >= MAX_PROPS:
			break
		if rng.randf() <= ROAD_PROB:
			var data := _weighted_pick(pool, rng)
			var pos := _roadside_candidate(baked, i, rng)
			if _passes_keepout(pos, data, baked, placed, layout, ROAD_MIN, ROAD_MAX, true):
				placed.append(_make_prop(pos, data))
		i += step_idx


static func _roadside_candidate(baked: PackedVector2Array, i: int, rng: RandomNumberGenerator) -> Vector2:
	var a := baked[maxi(i - 1, 0)]
	var b := baked[mini(i + 1, baked.size() - 1)]
	var dir := b - a
	if dir.length() < 0.001:
		return baked[i]
	dir = dir.normalized()
	var normal := Vector2(-dir.y, dir.x)
	var side := 1.0 if rng.randf() < 0.5 else -1.0
	var d := rng.randf_range(ROAD_MIN, ROAD_MAX)
	return baked[i] + normal * side * d


# Единый предикат. check_other_props=true — строгий (зазор до всех пропсов);
# false — ослабленный для гарантии: дерево может наехать на мелкий куст/скамейку,
# но всё ещё не лезет на тропу/слот/ларёк (геймплейные объекты защищены всегда).
static func _passes_keepout(pos: Vector2, data: PropData, baked: PackedVector2Array, placed: Array[Prop], layout: MapLayout, min_path: float, max_path: float, check_other_props: bool) -> bool:
	if not _inside_arena(pos, data):
		return false
	var d := MapValidator._min_distance_to_polyline(pos, baked)
	if d < min_path or d > max_path:
		return false
	var pr := _prop_rect(pos, data)
	if _rect_gap(pr, _base_rect(layout.base_position)) < PROP_BASE_GAP:
		return false
	for s in layout.tower_slot_positions:
		if _rect_gap(pr, _slot_rect(s)) < PROP_SLOT_GAP:
			return false
	if check_other_props:
		for p in placed:
			if _rect_gap(pr, _prop_rect(p.position, p.data)) < PROP_GAP:
				return false
	return true


static func _inside_arena(pos: Vector2, data: PropData) -> bool:
	var arena := MapValidator.ARENA_SIZE
	var hw := data.clearance_radius
	var bh := data.body_height
	return pos.x >= hw and pos.x <= arena.x - hw \
		and pos.y >= bh and pos.y <= arena.y - FOOT_MARGIN


static func _prop_rect(pos: Vector2, data: PropData) -> Rect2:
	var hw := data.clearance_radius
	var bh := data.body_height
	return Rect2(pos.x - hw, pos.y - bh, hw * 2.0, bh)

static func _slot_rect(center: Vector2) -> Rect2:
	return Rect2(center.x - SLOT_HALF, center.y - SLOT_HALF, SLOT_HALF * 2.0, SLOT_HALF * 2.0)

static func _base_rect(center: Vector2) -> Rect2:
	return Rect2(center.x - BASE_HALF, center.y - BASE_HALF, BASE_HALF * 2.0, BASE_HALF * 2.0)


static func _rect_gap(a: Rect2, b: Rect2) -> float:
	var gx := maxf(0.0, maxf(a.position.x - b.end.x, b.position.x - a.end.x))
	var gy := maxf(0.0, maxf(a.position.y - b.end.y, b.position.y - a.end.y))
	return Vector2(gx, gy).length()


static func _make_prop(pos: Vector2, data: PropData) -> Prop:
	var p := Prop.new()
	p.data = data
	p.position = pos
	return p


static func _weighted_pick(pool: Array[PropData], rng: RandomNumberGenerator) -> PropData:
	var total := 0.0
	for d in pool:
		total += d.weight
	var x := rng.randf() * total
	var acc := 0.0
	for d in pool:
		acc += d.weight
		if x <= acc:
			return d
	return pool[pool.size() - 1]


# Двухпроходная гарантия инварианта role. Проход 1 — строгий keepout; если не
# хватило мест (плотная арена), проход 2 ослабляет зазор до других пропсов,
# но сохраняет защиту тропы/слотов/базы. Так MIN_TREES/MIN_LAMPS становятся
# жёсткими, а не вероятностными.
static func _ensure_role(placed: Array[Prop], pool: Array[PropData], rng: RandomNumberGenerator, baked: PackedVector2Array, layout: MapLayout, role: StringName, min_count: int, field: bool) -> void:
	var have := _count_role(placed, role)
	var need := min_count - have
	if need <= 0 or pool.is_empty():
		return
	var subset := _pool_by_role(pool, role)
	if subset.is_empty():
		push_warning("PropGenerator: в пуле нет role='%s' — гарантию выполнить нельзя." % String(role))
		return
	need = _fill_role(placed, subset, rng, baked, layout, field, need, true)    # строгий
	if need > 0:
		need = _fill_role(placed, subset, rng, baked, layout, field, need, false)  # ослабленный
	if need > 0:
		push_warning("PropGenerator: не удалось добить role='%s' до %d (осталось %d) — арена переполнена." % [String(role), min_count, need])


static func _fill_role(placed: Array[Prop], subset: Array[PropData], rng: RandomNumberGenerator, baked: PackedVector2Array, layout: MapLayout, field: bool, need: int, strict: bool) -> int:
	var arena := MapValidator.ARENA_SIZE
	var tries := 0
	while need > 0 and tries < GUARANTEE_TRIES:
		tries += 1
		var data := _weighted_pick(subset, rng)
		var pos: Vector2
		if field:
			pos = Vector2(rng.randf_range(data.clearance_radius, arena.x - data.clearance_radius),
				rng.randf_range(data.body_height, arena.y - FOOT_MARGIN))
			if not _passes_keepout(pos, data, baked, placed, layout, OPEN_MIN, INF, strict):
				continue
		else:
			var hi := maxi(baked.size() - 2, 1)
			var i := rng.randi_range(1, hi)
			pos = _roadside_candidate(baked, i, rng)
			if not _passes_keepout(pos, data, baked, placed, layout, ROAD_MIN, ROAD_MAX, strict):
				continue
		placed.append(_make_prop(pos, data))
		need -= 1
	return need


static func _count_role(placed: Array[Prop], role: StringName) -> int:
	var c := 0
	for p in placed:
		if p.data.role == role:
			c += 1
	return c


static func _pool_by_role(pool: Array[PropData], role: StringName) -> Array[PropData]:
	var out: Array[PropData] = []
	for d in pool:
		if d.role == role:
			out.append(d)
	return out


static func _pool_by_roles(pool: Array[PropData], roles: Array[StringName]) -> Array[PropData]:
	var out: Array[PropData] = []
	for d in pool:
		if d.role in roles:
			out.append(d)
	return out


static func _pool_complement(pool: Array[PropData], roles: Array[StringName]) -> Array[PropData]:
	var out: Array[PropData] = []
	for d in pool:
		if not (d.role in roles):
			out.append(d)
	return out


static func _fisher_yates(arr: PackedVector2Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
