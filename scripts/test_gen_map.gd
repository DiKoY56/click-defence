extends Node2D
# PoC Фазы A: собираем карту из layout в рантайме и гоняем по ней поток врагов.
# Порядок присваиваний повторяет enemy_spawner.gd 1:1 — в этом смысл паритета.
# Layout прогоняется через MapValidator ДО сборки: битая карта не строится.

const EnemyScene: PackedScene = preload("res://scenes/enemy.tscn")

func _ready() -> void:
	var layout := MapLayout.new()
	# Вход слева ЗА краем арены (x=-160), змейка монотонно вправо к базе.
	layout.path_points = PackedVector2Array([
		Vector2(-160, 540),
		Vector2(300, 300),
		Vector2(650, 780),
		Vector2(1000, 320),
		Vector2(1350, 760),
		Vector2(1650, 540),
		Vector2(1780, 540),
	])
	layout.base_position = Vector2(1820, 540)
	# Слоты в «карманах» между изгибами, на ~180 от дороги: не на пути, но в радиусе башен.
	layout.tower_slot_positions = PackedVector2Array([
		Vector2(300, 120),
		Vector2(650, 960),
		Vector2(1000, 140),
		Vector2(1350, 940),
		Vector2(1650, 360),
	])

	var errors := MapValidator.validate(layout)
	if not errors.is_empty():
		for e in errors:
			push_error("MapValidator: " + e)
		return   # битую карту не собираем — ровно так Фаза B отбракует неудачный сид

	var builder := MapBuilder.new()
	add_child(builder)
	builder.build(layout)

	var ed: EnemyData = load("res://assets/data/enemy_normal.tres")
	for i in 5:
		_spawn_enemy(builder, ed)
		await get_tree().create_timer(1.2).timeout

func _spawn_enemy(builder: MapBuilder, ed: EnemyData) -> void:
	var enemy: Enemy = EnemyScene.instantiate() as Enemy
	enemy.path = builder.enemy_path   # ДО add_child — как в спавнере
	enemy.base = builder.base         # ДО add_child
	enemy.setup(ed)                   # ДО add_child
	add_child(enemy)
