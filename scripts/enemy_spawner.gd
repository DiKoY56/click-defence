extends Node

@export var path: Path2D
@export var base: Base
@export var enemy_count: int = 5
@export var spawn_interval: float = 1.0

@onready var spawn_timer: Timer = $SpawnTimer

const EnemyScene: PackedScene = preload("res://scenes/enemy.tscn")

var spawned: int = 0

func spawn_enemy() -> void:
	var enemy: Enemy = EnemyScene.instantiate() as Enemy
	enemy.path = path
	enemy.base = base
	add_child(enemy)
	
func _ready() -> void:
	spawn_timer.start()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer)
	
func _on_spawn_timer() -> void:
	if spawned >= enemy_count:
		spawn_timer.stop()
		return
	spawn_enemy()
	spawned += 1

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		spawn_enemy()
