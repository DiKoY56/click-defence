class_name MapGenerator
extends RefCounted
# Генерирует контрольные точки пути (спавн за левым краем -> база) с монотонным X.
# Монотонный X = гарантия отсутствия самопересечений и продвижения к базе.
# Чистая функция от rng: тот же сид -> тот же путь (воспроизводимость для дебага
# и для контроль-прогонов Фазы F).

const ARENA_SIZE := Vector2(1920, 1080)
const MARGIN_SPAWN := 150.0     # спавн за левым краем (запас на спрайт врага)
const V_PAD := 120.0            # вертикальный отступ контрольных точек от краёв
const H_PAD_END := 120.0        # отступ последней точки от базы по горизонтали
const MIN_SEGMENT := 220.0      # мин. горизонтальный шаг между точками
const AMP := 380.0              # амплитуда змейки по вертикали
const PULL_TO_CENTER := 0.30    # коэффициент возврата к средней линии (без дрейфа в угол)
const POINTS_MIN := 5
const POINTS_MAX := 8


static func generate_path(rng: RandomNumberGenerator, base_pos: Vector2) -> PackedVector2Array:
	var center_y := ARENA_SIZE.y * 0.5
	# старт ЗА левым краем (с запасом, чтобы валидатор не ловил грань)
	var start := Vector2(
		-(MARGIN_SPAWN + rng.randf_range(0.0, 80.0)),
		rng.randf_range(V_PAD, ARENA_SIZE.y - V_PAD)
	)
	# финиш у базы
	var end := Vector2(base_pos.x - H_PAD_END, base_pos.y)

	var k := rng.randi_range(POINTS_MIN, POINTS_MAX)
	var xs := _split_horizontal(start.x, end.x, k, rng)

	var pts := PackedVector2Array()
	pts.append(start)
	var prev := start
	for i in range(xs.size()):
		# возврат к центру + шум, кламп в вертикальное окно арены
		var y := lerpf(prev.y, center_y, PULL_TO_CENTER) + rng.randf_range(-AMP, AMP)
		y = clampf(y, V_PAD, ARENA_SIZE.y - V_PAD)
		var p := Vector2(xs[i], y)
		pts.append(p)
		prev = p
	pts.append(end)
	return pts


# Разбивает [x0, x1] на (k+1) интервалов, каждый >= MIN_SEGMENT, с монотонным X.
# Метод «sticks»: фиксированный минимум + случайное распределение остатка.
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
	if sum_b <= 0.0:   # защита от деления на ноль (маловероятно)
		var step := total / float(k + 1)
		for i in range(k):
			acc += step
			xs.append(acc)
		return xs
	for i in range(k):
		acc += MIN_SEGMENT + bonuses[i] / sum_b * free
		xs.append(acc)
	return xs
