extends Node2D
# PoC Фазы D: полная процедурная карта (путь+слоты+декор) + поток врагов.
# Проверяем: земля под всем, пропсы под боем (z -10), не перекрывают слоты/путь,
# гарантия деревьев/фонарей, детерминизм по ситу. R = реролл.

const EnemyScene: PackedScene = preload("res://scenes/enemy.tscn")
const BASE_POS := Vector2(1820, 540)
const MAX_ATTEMPTS := 40

var FALLBACK_PATH := PackedVector2Array([
	Vector2(-160, 540), Vector2(300, 300), Vector2(650, 780),
	Vector2(1000, 320), Vector2(1350, 760), Vector2(1650, 540), Vector2(1780, 540),
])

var builder: MapBuilder = null
var path_overlay: PathOverlay = null
var slot_overlay: SlotOverlay = null
var info_label: Label = null
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

	builder = MapBuilder.new()
	add_child(builder)
	builder.build(layout, rng)   # <-- rng включаем декор

	var baked := MapValidator._bake_path(layout.path_points)
	var errs := MapValidator.validate(layout)

	path_overlay = PathOverlay.new()
	add_child(path_overlay)
	path_overlay.set_data(baked, layout.path_points, "seed=%d  len=%.0f" % [seed_used, MapValidator._polyline_length(baked)])

	slot_overlay = SlotOverlay.new()
	add_child(slot_overlay)
	slot_overlay.set_data(layout.tower_slot_positions, baked, "")

	# статистика декора по role (скан детей билдера)
	var trees := 0
	var lamps := 0
	var others := 0
	for node in builder.get_children():
		var p := node as Prop
		if p == null or p.data == null:
			continue
		match p.data.role:
			&"tree": trees += 1
			&"lamp": lamps += 1
			_: others += 1

	info_label = Label.new()
	info_label.add_theme_font_override("font", preload("res://assets/fonts/PressStart2P-Regular.ttf"))
	info_label.add_theme_font_size_override("font_size", 14)
	info_label.add_theme_color_override("font_color", Color.WHITE)
	info_label.position = Vector2(20, 96)
	info_label.text = "props: trees=%d lamps=%d other=%d  errors=%d" % [trees, lamps, others, errs.size()]
	add_child(info_label)

	var ed: EnemyData = load("res://assets/data/enemy_normal.tres")
	for i in 5:
		_spawn_enemy(builder, ed)
		await get_tree().create_timer(1.2).timeout

	for e in errs:
		push_error("MapValidator: " + e)
	print("seed=", seed_used, " trees=", trees, " lamps=", lamps, " other=", others, " errors=", errs.size())

func _generate_valid_layout() -> MapLayout:
	for attempt in range(MAX_ATTEMPTS):
		var pts := MapGenerator.generate_path(rng, BASE_POS)
		var layout := MapLayout.new()
		layout.path_points = pts
		layout.base_position = BASE_POS
		layout.tower_slot_positions = MapGenerator.generate_slots(layout, rng)
		if MapValidator.validate(layout).is_empty():
			return layout
	var fb := MapLayout.new()
	fb.path_points = FALLBACK_PATH
	fb.base_position = BASE_POS
	fb.tower_slot_positions = PackedVector2Array([
		Vector2(300, 120), Vector2(650, 960), Vector2(1000, 140),
		Vector2(1350, 940), Vector2(1650, 360),
	])
	return fb

func _spawn_enemy(builder_ref: MapBuilder, ed: EnemyData) -> void:
	var enemy: Enemy = EnemyScene.instantiate() as Enemy
	enemy.path = builder_ref.enemy_path
	enemy.base = builder_ref.base
	enemy.setup(ed)
	add_child(enemy)

func _clear() -> void:
	for node in [builder, path_overlay, slot_overlay, info_label]:
		if node and is_instance_valid(node):
			node.queue_free()
	builder = null
	path_overlay = null
	slot_overlay = null
	info_label = null
