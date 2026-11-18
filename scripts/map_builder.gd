class_name MapBuilder
extends Node2D
# Собирает карту из MapLayout в рантайме, повторяя структуру .tscn-карт.
# Наружу отдаёт enemy_path / base в том же виде, что и map.gd (duck-typing).
# Декор (земля + тропа + пропсы) включается, если передан rng.

const BaseScene: PackedScene = preload("res://scenes/base.tscn")
const BaseScript: Script = preload("res://scripts/base.gd")
const TowerSlotScene: PackedScene = preload("res://scenes/tower_slot.tscn")

const GROUND_Z := -20
const TRAIL_Z := -15
const PROP_Z := -10

var enemy_path: Path2D = null
var base: Base = null
var ground: Ground = null

func build(layout: MapLayout, rng: RandomNumberGenerator = null) -> void:
	enemy_path = Path2D.new()
	enemy_path.name = "EnemyPath"
	var curve := Curve2D.new()
	for p in layout.path_points:
		curve.add_point(p)
	enemy_path.curve = curve
	add_child(enemy_path)

	var base_node := BaseScene.instantiate()
	base_node.set_script(BaseScript)
	base_node.position = layout.base_position
	add_child(base_node)
	base = base_node as Base
	if base == null:
		push_error("MapBuilder: не удалось превратить base.tscn в Base (проверь base.gd)")

	for i in layout.tower_slot_positions.size():
		var slot := TowerSlotScene.instantiate()
		slot.name = "TowerSlot%d" % (i + 1)
		slot.position = layout.tower_slot_positions[i]
		add_child(slot)

	if rng != null:
		_build_decor(layout, rng)

func _build_decor(layout: MapLayout, rng: RandomNumberGenerator) -> void:
	ground = Ground.new()
	ground.name = "Ground"
	ground.z_index = GROUND_Z
	add_child(ground)

	var trail := Trail.new()
	trail.name = "Trail"
	trail.z_index = TRAIL_Z
	trail.setup(layout.path_points, layout.base_position)   # ← база нужна для обрезки хвоста
	add_child(trail)

	var props := PropGenerator.generate_props(layout, rng)
	for p in props:
		p.z_index = PROP_Z
		add_child(p)
