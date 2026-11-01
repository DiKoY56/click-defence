class_name MapBuilder
extends Node2D
# Собирает карту из MapLayout в рантайме, повторяя структуру ваших .tscn-карт.
# Наружу отдаёт enemy_path / base в том же виде, что и map.gd — поэтому main.gd
# работает с собранной картой без изменений (duck-typing по полям).
# Декор (земля + пропсы) включается, если передан rng; без него — чистая геометрия
# (старые тесты Фаз A/C вызывают build(layout) и поведения не меняют).

const BaseScene: PackedScene = preload("res://scenes/base.tscn")
const BaseScript: Script = preload("res://scripts/base.gd")
const TowerSlotScene: PackedScene = preload("res://scenes/tower_slot.tscn")

const GROUND_Z := -20
const PROP_Z := -10

var enemy_path: Path2D = null
var base: Base = null
var ground: Ground = null

func build(layout: MapLayout, rng: RandomNumberGenerator = null) -> void:
	# --- путь врагов ---
	enemy_path = Path2D.new()
	enemy_path.name = "EnemyPath"
	var curve := Curve2D.new()
	for p in layout.path_points:
		curve.add_point(p)
	enemy_path.curve = curve
	add_child(enemy_path)

	# --- база (скрипт назначаем явно: в base.tscn его нет в корне) ---
	var base_node := BaseScene.instantiate()
	base_node.set_script(BaseScript)
	base_node.position = layout.base_position
	add_child(base_node)
	base = base_node as Base
	if base == null:
		push_error("MapBuilder: не удалось превратить base.tscn в Base (проверь base.gd)")

	# --- слоты под башни ---
	for i in layout.tower_slot_positions.size():
		var slot := TowerSlotScene.instantiate()
		slot.name = "TowerSlot%d" % (i + 1)
		slot.position = layout.tower_slot_positions[i]
		add_child(slot)

	# --- декор (только если передан rng) ---
	if rng != null:
		_build_decor(layout, rng)

func _build_decor(layout: MapLayout, rng: RandomNumberGenerator) -> void:
	ground = Ground.new()
	ground.name = "Ground"
	ground.z_index = GROUND_Z
	add_child(ground)

	var props := PropGenerator.generate_props(layout, rng)
	for p in props:
		p.z_index = PROP_Z
		add_child(p)
