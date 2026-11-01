class_name MapBuilder
extends Node2D
# Собирает карту из MapLayout в рантайме, повторяя структуру ваших .tscn-карт.
# Наружу отдаёт enemy_path / base в том же виде, что и map.gd — поэтому main.gd
# работает с собранной картой без изменений (duck-typing по полям).

const BaseScene: PackedScene = preload("res://scenes/base.tscn")
const BaseScript: Script = preload("res://scripts/base.gd")   # ← скрипт базы
const TowerSlotScene: PackedScene = preload("res://scenes/tower_slot.tscn")

var enemy_path: Path2D = null
var base: Base = null

func build(layout: MapLayout) -> void:
	# --- путь врагов ---
	enemy_path = Path2D.new()
	enemy_path.name = "EnemyPath"
	var curve := Curve2D.new()
	for p in layout.path_points:
		curve.add_point(p)
	enemy_path.curve = curve
	add_child(enemy_path)

	# --- база ---
	# В base.tscn скрипт base.gd НЕ зашит в корень: карты навешивают его на инстанс
	# в инспекторе. При программной сборке назначаем скрипт явно, ДО add_child,
	# иначе _ready отработает без Base-логики (health, сигналы, @onready sprite).
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
