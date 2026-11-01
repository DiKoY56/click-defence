extends Node2D
# PoC Фазы B: генерируем путь по ситу, валидируем, рисуем. Слотов ещё нет (Фаза C).
# Демонстрирует полный цикл: generate -> validate -> retry -> fallback.
# R = реролл (новый сид). Печатает сид и длину, чтобы дебажить разброс.

const BASE_POS := Vector2(1820, 540)
const MAX_ATTEMPTS := 40

# Рукописный фолбэк-путь (валиден по всем правилам) — если ретраи исчерпаны.
# ВАЖНО: var, не const — PackedVector2Array из литералов не является
# константным выражением в GDScript 4 (в отличие от Vector2 выше).
var FALLBACK_PATH := PackedVector2Array([
	Vector2(-160, 540), Vector2(300, 300), Vector2(650, 780),
	Vector2(1000, 320), Vector2(1350, 760), Vector2(1650, 540), Vector2(1780, 540),
])

var builder: MapBuilder = null
var overlay: PathOverlay = null
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = randi()
	_reroll()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		rng.seed = randi()
		_reroll()

func _reroll() -> void:
	_clear()
	var seed_used := rng.seed
	var pts := _generate_valid_path()
	var used_fallback := (pts == FALLBACK_PATH)

	var layout := MapLayout.new()
	layout.path_points = pts
	layout.base_position = BASE_POS
	# слотов пока нет — builder отработает по пустому массиву

	builder = MapBuilder.new()
	add_child(builder)
	builder.build(layout)

	var baked := MapValidator._bake_path(pts)
	var length := MapValidator._polyline_length(baked)
	var errs := MapValidator.validate_path(layout)

	overlay = PathOverlay.new()
	add_child(overlay)
	overlay.set_data(baked, pts, "seed=%d  len=%.0f%s" % [seed_used, length, ("  [FALLBACK]" if used_fallback else "")])

	if used_fallback:
		push_warning("Ретраи исчерпаны (%d), использован фолбэк-путь. Сид: %d" % [MAX_ATTEMPTS, seed_used])
	for e in errs:
		push_error("MapValidator: " + e)
	print("seed=", seed_used, " len=", int(length), " attempts_ok=", not used_fallback, " errors=", errs.size())

func _generate_valid_path() -> PackedVector2Array:
	for attempt in range(MAX_ATTEMPTS):
		var pts := MapGenerator.generate_path(rng, BASE_POS)
		var layout := MapLayout.new()
		layout.path_points = pts
		layout.base_position = BASE_POS
		if MapValidator.validate_path(layout).is_empty():
			return pts
	return FALLBACK_PATH

func _clear() -> void:
	if builder and is_instance_valid(builder):
		builder.queue_free()
	if overlay and is_instance_valid(overlay):
		overlay.queue_free()
	builder = null
	overlay = null
