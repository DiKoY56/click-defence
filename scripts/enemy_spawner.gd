class_name EnemySpawner
extends Node

signal enemy_died
signal enemy_killed

@export var path: Path2D
@export var base: Base
@export var enemy_count: int = 5
@export var spawn_interval: float = 1.0
@export var enemy_types: Array[EnemyData]

@onready var spawn_timer: Timer = $SpawnTimer

const EnemyScene: PackedScene = preload("res://scenes/enemy.tscn")

var spawned: int = 0

var is_boss_wave: bool = false

func spawn_enemy() -> void:
	var enemy: Enemy = EnemyScene.instantiate() as Enemy
	enemy.path = path
	enemy.base = base
	enemy.setup(pick_enemy_type())
	var hp_mult: float = pow(1.13, WaveManager.current_wave - 1)
	enemy.max_health = int(enemy.max_health * hp_mult)
	enemy.killed.connect(_on_enemy_killed)
	
	if is_boss_wave and spawned == 0:
		#первый враг на босс-волне это БОСС
		enemy.max_health *= 10
		enemy.gold_reward *= 5
		#попозже другой спрайт и размер
	enemy.died.connect(_on_enemy_died)
	add_child(enemy)
	
func _ready() -> void:
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer)
	
func _on_spawn_timer() -> void:
	if WaveManager.is_game_over:
		return
		
	if spawned >= enemy_count:
		spawn_timer.stop()
		return
	spawn_enemy()
	spawned += 1

func _unhandled_input(event: InputEvent) -> void:
	if WaveManager.is_game_over:
		return
		
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		spawn_enemy()
		
func start_spawning() -> void:
	spawn_timer.start()

func set_wave_config(count: int, boss_wave: bool) -> void:
	enemy_count = count
	is_boss_wave = boss_wave
	spawned = 0

func _on_enemy_died() -> void:
	enemy_died.emit()

func pick_enemy_type() -> EnemyData:
	var available: Array[EnemyData] = []
	for t in enemy_types:
		if t.unlock_wave <= WaveManager.current_wave:
			available.append(t)
	if available.is_empty():
		return enemy_types[0]   # страховка
	return available.pick_random()

func stop_spawning() -> void:
	spawn_timer.stop()

func _on_enemy_killed() -> void: 
	enemy_killed.emit()
