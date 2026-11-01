extends Node2D
# PoC Фазы C: генерируем путь + слоты, валидируем полный layout, рисуем near/far,
# гоняем поток врагов чтобы убедиться что они идут и НЕ задевают слоты.
# Строительство башен на процедурной карте проверяем в Фазе E (интеграция с main);
# здесь предмет — геометрия расстановки.

const EnemyScene: PackedScene = preload("res://scenes/enemy.tscn")   # ← была потеряна
const BASE_POS := Vector2(1820, 540)
const MAX_ATTEMPTS := 40

var FALLBACK_PATH := PackedVector2Array([
	Vector2(-160, 540), Vector2(300, 300), Vector2(650, 780),
	Vector2(1000, 320), Vector2(1350, 760), Vector2(1650, 540), Vector2(1780, 540),
])

var builder: MapBuilder = null
var path_overlay: PathOverlay = null
var slot_overlay: SlotOverlay = null
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
	var layout := _generate_valid_layout()
	var used_fallback := (layout.path_points == FALLBACK_PATH)

	builder = MapBuilder.new()
	add_child(builder)
	builder.build(layout)

	var baked := MapValidator._bake_path(layout.path_points)
	var errs := MapValidator.validate(layout)

	# near/far статистика (класс выводится из dist, не хранится)
	var near := 0
	var far := 0
	for s in layout.tower_slot_positions:
		var d := MapValidator._min_distance_to_polyline(s, baked)
		if d <= MapValidator.SLOT_NEAR_DIST:
			near += 1
		else:
			far += 1

	path_overlay = PathOverlay.new()
	add_child(path_overlay)
	path_overlay.set_data(baked, layout.path_points, "seed=%d  len=%.0f%s" % [seed_used, MapValidator._polyline_length(baked), ("  [FALLBACK]" if used_fallback else "")])

	slot_overlay = SlotOverlay.new()
	add_child(slot_overlay)
	slot_overlay.set_data(layout.tower_slot_positions, baked, "slots=%d  near=%d  far=%d" % [layout.tower_slot_positions.size(), near, far])

	# поток врагов — визуальная проверка что они обходят слоты
	var ed: EnemyData = load("res://assets/data/enemy_normal.tres")
	for i in 5:
		_spawn_enemy(builder, ed)
		await get_tree().create_timer(1.2).timeout

	if used_fallback:
		push_warning("Ретраи исчерпаны (%d), фолбэк. Сид: %d" % [MAX_ATTEMPTS, seed_used])
	for e in errs:
		push_error("MapValidator: " + e)
	print("seed=", seed_used, " slots=", layout.tower_slot_positions.size(), " near=", near, " far=", far, " errors=", errs.size())

func _generate_valid_layout() -> MapLayout:
	for attempt in range(MAX_ATTEMPTS):
		var pts := MapGenerator.generate_path(rng, BASE_POS)
		var layout := MapLayout.new()
		layout.path_points = pts
		layout.base_position = BASE_POS
		layout.tower_slot_positions = MapGenerator.generate_slots(layout, rng)
		if MapValidator.validate(layout).is_empty():
			return layout
	# фолбэк: рукописный путь + его же рукописные слоты (валидны по всем правилам)
	var fb := MapLayout.new()
	fb.path_points = FALLBACK_PATH
	fb.base_position = BASE_POS
	fb.tower_slot_positions = PackedVector2Array([
		Vector2(300, 120), Vector2(650, 960), Vector2(1000, 140),
		Vector2(1350, 940), Vector2(1650, 360),
	])
	return fb

func _spawn_enemy(builder: MapBuilder, ed: EnemyData) -> void:
	var enemy: Enemy = EnemyScene.instantiate() as Enemy
	enemy.path = builder.enemy_path
	enemy.base = builder.base
	enemy.setup(ed)
	add_child(enemy)

func _clear() -> void:
	for node in [builder, path_overlay, slot_overlay]:
		if node and is_instance_valid(node):
			node.queue_free()
	builder = null
	path_overlay = null
	slot_overlay = null
