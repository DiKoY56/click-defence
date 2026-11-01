class_name ProceduralMap
extends Node2D
# Самодостаточный источник процедурной карты: в _ready генерирует layout
# (generate -> validate -> retry -> fallback), собирает геометрию+декор через
# MapBuilder и пробрасывает наружу .enemy_path / .base в том же виде, что и
# map.gd на рукописных картах. Поэтому main.gd работает с этой картой без
# изменений (duck-typing по полям) — он не различает источник.
#
# fixed_seed >= 0 -> детерминированная карта (для дебага/контроль-прогонов);
# fixed_seed == -1 -> случайная при каждом создании.

const MAX_ATTEMPTS := 40

@export var fixed_seed: int = -1

# Duck-type контракт с map.gd (заполняются в _ready после сборки).
var enemy_path: Path2D = null
var base: Base = null
# Диагностика для main/логов: сколько ошибок осталось и сработал ли фолбэк.
var last_errors: PackedStringArray = PackedStringArray()
var used_fallback: bool = false

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.seed = fixed_seed if fixed_seed >= 0 else randi()
	var layout := _generate_layout()
	last_errors = MapValidator.validate(layout)
	used_fallback = (layout.path_points == _fallback_path())

	var builder := MapBuilder.new()
	builder.name = "Builder"
	add_child(builder)
	builder.build(layout, _rng)

	# Проброс наружу — ровно те ссылки, что читает main.gd у рукописной карты.
	enemy_path = builder.enemy_path
	base = builder.base

	if used_fallback:
		push_warning("ProceduralMap: ретраи исчерпаны, использован фолбэк-layout. seed=%d" % _rng.seed)
	for e in last_errors:
		push_error("ProceduralMap validator: " + e)
	print("ProceduralMap ready: seed=", _rng.seed, " fallback=", used_fallback, " errors=", last_errors.size())


# Полный цикл: кандидаты из генератора, отбраковка валидатором, фолбэк после MAX_ATTEMPTS.
func _generate_layout() -> MapLayout:
	var base_pos := _fallback_base_pos()
	for attempt in range(MAX_ATTEMPTS):
		var pts := MapGenerator.generate_path(_rng, base_pos)
		var layout := MapLayout.new()
		layout.path_points = pts
		layout.base_position = base_pos
		layout.tower_slot_positions = MapGenerator.generate_slots(layout, _rng)
		if MapValidator.validate(layout).is_empty():
			return layout
	return _fallback_layout(base_pos)


# --- фолбэк: рукописный валидный layout (игра НИКОГДА не получит битую карту). ---
# TODO(F): унифицировать с фолбэками тестовых сцен в один MapGenerator.fallback_layout().
# Сейчас намеренно приватно и с дублированием: миграция зелёных тестов — отдельная
# задача чистки, смешивать её с интеграцией рискованно.
func _fallback_base_pos() -> Vector2:
	return Vector2(1820, 540)

func _fallback_path() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-160, 540), Vector2(300, 300), Vector2(650, 780),
		Vector2(1000, 320), Vector2(1350, 760), Vector2(1650, 540), Vector2(1780, 540),
	])

func _fallback_layout(base_pos: Vector2) -> MapLayout:
	var fb := MapLayout.new()
	fb.path_points = _fallback_path()
	fb.base_position = base_pos
	fb.tower_slot_positions = PackedVector2Array([
		Vector2(300, 120), Vector2(650, 960), Vector2(1000, 140),
		Vector2(1350, 940), Vector2(1650, 360),
	])
	return fb
