extends Node2D
# PoC Фазы E1: одна строка add_child(ProceduralMap) даёт полную карту
# (путь+слоты+декор). Проверяем duck-type контракт: враг идёт по map.enemy_path,
# бьёт map.base, слоты кликаются. Автономность источника доказана, если этот
# тест зелёный БЕЗ ручных вызовов MapGenerator/MapValidator/MapBuilder.

const EnemyScene: PackedScene = preload("res://scenes/enemy.tscn")

var map: ProceduralMap = null
var spawn_timer: Timer = null
var spawned := 0

func _ready() -> void:
	# Автосборка золота не нужна для ходьбы врага, но даём, чтобы можно было
	# вручную потыкать постройку башни на процедурной карте (autoloads живы в F6).
	EconomyManager.add_gold(9999)
	_build()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		_build()

func _build() -> void:
	_clear()
	spawned = 0
	map = ProceduralMap.new()      # <-- ВЕСЬ конвейер в одном add_child
	add_child(map)
	# Контракт читается ПОСЛЕ add_child: _ready уже отработал и пробросил поля.
	assert(map.enemy_path != null, "ProceduralMap не пробросил enemy_path")
	assert(map.base != null, "ProceduralMap не пробросил base")

	spawn_timer = Timer.new()
	spawn_timer.wait_time = 1.2
	spawn_timer.timeout.connect(_spawn_one)
	add_child(spawn_timer)
	spawn_timer.start()

func _spawn_one() -> void:
	if spawned >= 6:
		spawn_timer.stop()
		return
	spawned += 1
	var ed: EnemyData = load("res://assets/data/enemy_normal.tres")
	var enemy: Enemy = EnemyScene.instantiate() as Enemy
	enemy.path = map.enemy_path    # порядок спавнера: path/base/setup ДО add_child
	enemy.base = map.base
	enemy.setup(ed)
	add_child(enemy)

func _clear() -> void:
	if map and is_instance_valid(map):
		map.queue_free()
	if spawn_timer and is_instance_valid(spawn_timer):
		spawn_timer.queue_free()
	map = null
	spawn_timer = null
