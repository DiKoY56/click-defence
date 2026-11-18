class_name ProceduralMap
extends Node2D
# Единый источник карты в рантайме: собирает geometry+decor через MapBuilder и
# пробрасывает .enemy_path / .base (тот же контракт, что был у map.gd).
# Источник layout'а:
#   use_procedural=true  -> генератор (generate -> validate -> retry -> fallback)
#   use_procedural=false -> пул авторских MapLayout (.tres), БЕЗ валидации:
#                           авторская карта — дизайн-интент, а не кандидат генератора.
# Фолбэк генератора = тот же пул авторских карт: битая карта не доедет до игрока.

const MAX_ATTEMPTS := 40
const BASE_POS := Vector2(1820, 540)
const HAND_LAYOUTS: Array[MapLayout] = [
	preload("res://assets/data/map_hand_1.tres"),
	preload("res://assets/data/map_hand_2.tres"),
	preload("res://assets/data/map_hand_3.tres"),
]

@export var use_procedural: bool = true
@export var fixed_seed: int = -1

var enemy_path: Path2D = null
var base: Base = null
var last_errors: PackedStringArray = PackedStringArray()
var used_fallback: bool = false

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.seed = fixed_seed if fixed_seed >= 0 else randi()
	var layout: MapLayout
	if use_procedural:
		layout = _generate_layout()
		if not used_fallback:
			last_errors = MapValidator.validate(layout)
	else:
		layout = HAND_LAYOUTS.pick_random()

	var builder := MapBuilder.new()
	builder.name = "Builder"
	add_child(builder)
	builder.build(layout, _rng)

	enemy_path = builder.enemy_path
	base = builder.base

	if used_fallback:
		push_warning("ProceduralMap: ретраи исчерпаны, взят авторский layout. seed=%d" % _rng.seed)
	for e in last_errors:
		push_error("ProceduralMap validator: " + e)
	print("ProceduralMap ready: mode=", ("proc" if use_procedural else "hand"), " seed=", _rng.seed, " fallback=", used_fallback, " errors=", last_errors.size())


func _generate_layout() -> MapLayout:
	for attempt in range(MAX_ATTEMPTS):
		var pts := MapGenerator.generate_path(_rng, BASE_POS)
		var layout := MapLayout.new()
		layout.path_points = pts
		layout.base_position = BASE_POS
		layout.tower_slot_positions = MapGenerator.generate_slots(layout, _rng)
		if MapValidator.validate(layout).is_empty():
			return layout
	used_fallback = true
	return HAND_LAYOUTS.pick_random()
