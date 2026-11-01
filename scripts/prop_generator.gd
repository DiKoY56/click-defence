class_name PropGenerator
extends RefCounted
# Авторасстановка пропсов парка по джиттер-сетке с отбраковкой по путь/слоты/база/
# соседям (мягкий радиальный предикат — см. решение №4) + guarantee-pass по role.
# Геометрию пути/слотов берёт из MapValidator (единый источник истины).
# Чисто от rng: тот же сид -> тот же декор.

const CELL := 150.0
const JITTER := 42.0
const DENSITY := 0.55          # доля ячеек сетки, где пробуем ставить пропс
const MAX_PROPS := 26
const EDGE_MARGIN := 30.0      # пропс может частично свисать за край (рамка кадра)
const PROP_PATH_CLEAR := 70.0  # держим ствол/ножку от линии ходьбы
const PROP_GAP := 12.0         # воздух между пропсами
const BASE_HALF := 120.0       # полуширина ларька (арт 128 *2 /2 ~ 128, берём 120)
const SLOT_HALF := 64.0
const MIN_TREES := 3
const MIN_LAMPS := 1
const GUARANTEE_TRIES := 40
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
		push_warning("PropGenerator: пул prop_*.tres пуст — декор не расставлен (положите .tres в assets/data).")
		return []

	var baked := MapValidator._bake_path(layout.path_points)
	if baked.size() < 2:
		return []
	var arena := MapValidator.ARENA_SIZE
	var inner := Rect2(Vector2(EDGE_MARGIN, EDGE_MARGIN), arena - Vector2(EDGE_MARGIN, EDGE_MARGIN) * 2.0)

	# ячейки сетки -> перемешиваем нашим rng (детерминированно) -> проходим по очереди
	var cells := PackedVector2Array()
	var cols := ceili(arena.x / CELL)
	var rows := ceili(arena.y / CELL)
	for cy in rows:
		for cx in cols:
			cells.append(Vector2((cx + 0.5) * CELL, (cy + 0.5) * CELL))
	_fisher_yates(cells, rng)

	var placed: Array[Prop] = []
	for center in cells:
		if placed.size() >= MAX_PROPS:
			break
		if rng.randf() > DENSITY:
			continue
		var data := _weighted_pick(pool, rng)
		var pos := center + Vector2(rng.randf_range(-JITTER, JITTER), rng.randf_range(-JITTER, JITTER))
		if not inner.has_point(pos):
			continue
		if not _passes_keepout(pos, data, baked, placed, layout):
			continue
		placed.append(_make_prop(pos, data))

	_ensure_role(placed, pool, rng, baked, layout, inner, &"tree", MIN_TREES)
	_ensure_role(placed, pool, rng, baked, layout, inner, &"lamp", MIN_LAMPS)
	return placed


static func _make_prop(pos: Vector2, data: PropData) -> Prop:
	var p := Prop.new()
	p.data = data
	p.position = pos
	return p


# Мягкий радиальный предикат: путь, база, слоты, уже поставленные пропсы.
static func _passes_keepout(pos: Vector2, data: PropData, baked: PackedVector2Array, placed: Array[Prop], layout: MapLayout) -> bool:
	var r := data.clearance_radius
	if MapValidator._min_distance_to_polyline(pos, baked) < PROP_PATH_CLEAR + r:
		return false
	if pos.distance_to(layout.base_position) < BASE_HALF + r:
		return false
	for s in layout.tower_slot_positions:
		if pos.distance_to(s) < SLOT_HALF + r:
			return false
	for p in placed:
		if pos.distance_to(p.position) < p.data.clearance_radius + r + PROP_GAP:
			return false
	return true


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


# Guarantee: досаживаем недостающие role случайными позициями внутри inner.
static func _ensure_role(placed: Array[Prop], pool: Array[PropData], rng: RandomNumberGenerator, baked: PackedVector2Array, layout: MapLayout, inner: Rect2, role: StringName, min_count: int) -> void:
	var have := 0
	for p in placed:
		if p.data.role == role:
			have += 1
	var need := min_count - have
	if need <= 0:
		return
	var subset := _pool_by_role(pool, role)
	if subset.is_empty():
		push_warning("PropGenerator: в пуле нет пропсов с role='%s' — гарантию выполнить нельзя." % String(role))
		return
	var tries := 0
	while need > 0 and tries < GUARANTEE_TRIES:
		tries += 1
		var pos := Vector2(rng.randf_range(inner.position.x, inner.end.x), rng.randf_range(inner.position.y, inner.end.y))
		var data := _weighted_pick(subset, rng)
		if not _passes_keepout(pos, data, baked, placed, layout):
			continue
		placed.append(_make_prop(pos, data))
		need -= 1


static func _pool_by_role(pool: Array[PropData], role: StringName) -> Array[PropData]:
	var out: Array[PropData] = []
	for d in pool:
		if d.role == role:
			out.append(d)
	return out


static func _fisher_yates(arr: PackedVector2Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
