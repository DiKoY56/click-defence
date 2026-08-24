extends Node

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal boss_incoming
signal game_won
signal game_lost

const TOTAL_WAVES: int = 10
const WAVE_PAUSE: float = 5.0 
const BASE_ENEMY_COUNT: int = 5
const ENEMY_GROWTH: float = 1.3

const BOSS_WAVES: Array[int] = [5, 10]
const BOSS_HEALTH_MULTIPLIER: int = 10

var current_wave: int = 0
var enemies_spawned: int = 0
var enemies_alive: int = 0
var is_wave_active: bool = false
var is_game_over: bool = false
var total_kills: int = 0
var run_start_ticks: int = 0
var final_time_sec: int = 0

@onready var wave_timer: Timer = $WaveTimer
@onready var spawner: EnemySpawner
@onready var base: Base

func setup(new_spawner: EnemySpawner, new_base: Base) -> void:
	spawner = new_spawner
	base = new_base
	base.destroyed.connect(_on_base_destroyed)
	spawner.enemy_died.connect(_on_enemy_died)
	spawner.enemy_killed.connect(_on_enemy_killed)
	
func start_game() -> void:
	current_wave = 0
	run_start_ticks = Time.get_ticks_msec()
	_start_next_wave()

func _start_next_wave() -> void:
	if is_game_over:
		return
		
	current_wave += 1
	
	if current_wave > TOTAL_WAVES:
		is_game_over = true
		final_time_sec = int((Time.get_ticks_msec() - run_start_ticks) / 1000.0)
		game_won.emit()
		return
	
	var enemy_count: int = int(BASE_ENEMY_COUNT * pow(ENEMY_GROWTH, current_wave - 1))
	var is_boss_wave: bool = current_wave in BOSS_WAVES
	
	if is_boss_wave:
		boss_incoming.emit()
		# На волне босса 1 босс + половина обычных врагов
		@warning_ignore("integer_division")
		enemy_count = 1 + (enemy_count / 2)
	
	enemies_spawned = 0
	enemies_alive = enemy_count
	is_wave_active = true
	
	spawner.set_wave_config(enemy_count, is_boss_wave)
	spawner.start_spawning()
	
	wave_started.emit(current_wave)

func _on_enemy_died() -> void:
	if is_game_over or not is_wave_active:
		return 
	
	enemies_alive -=1
	
	if enemies_alive <= 0:
		is_wave_active = false
		wave_completed.emit(current_wave)
		wave_timer.start(WAVE_PAUSE)

func _on_wave_timer_timeout() -> void:
	_start_next_wave()

func _on_base_destroyed() -> void:
	if is_game_over:
		return
	is_game_over = true
	wave_timer.stop()
	spawner.stop_spawning()
	_clear_remaining_enemies()
	final_time_sec = int((Time.get_ticks_msec() - run_start_ticks) / 1000.0)
	game_lost.emit()

func _clear_remaining_enemies() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	
func _ready() -> void:
	wave_timer.timeout.connect(_on_wave_timer_timeout)

func reset() -> void:
	current_wave = 0
	enemies_alive = 0
	is_wave_active = false
	is_game_over = false
	total_kills = 0
	wave_timer.stop()
	final_time_sec = 0

func _on_enemy_killed() -> void:
	total_kills += 1
