extends Node2D

func _ready() -> void:
	UpgradeManager.reset()
	EconomyManager.reset()
	WaveManager.reset()
	BuffManager.reset()

	# Один пайплайн: ProceduralMap сам решает источник (генератор или авторский пул)
	# и отдаёт .enemy_path/.base в том же виде, что раньше отдавали map_*.tscn.
	var map := ProceduralMap.new()
	map.use_procedural = SaveManager.procedural_maps
	$MapHolder.add_child(map)

	$EnemySpawner.path = map.enemy_path
	$EnemySpawner.base = map.base
	$UI/HUD.setup(map.base)

	WaveManager.game_won.connect(_on_game_won)
	WaveManager.game_lost.connect(_on_game_lost)
	WaveManager.wave_completed.connect(_on_wave_completed)
	WaveManager.setup($EnemySpawner, map.base)
	WaveManager.start_game()

func _on_wave_completed(wave_number: int) -> void:
	if wave_number < WaveManager.TOTAL_WAVES:
		$UI/BuffScreen.show_choices()
	else:
		WaveManager.proceed_to_next_wave()

func _on_game_won() -> void:
	var new_record := SaveManager.submit_run(WaveManager.TOTAL_WAVES, WaveManager.total_kills, true)
	$UI/EndScreen.show_end(true, WaveManager.TOTAL_WAVES, WaveManager.total_kills, WaveManager.final_time_sec, new_record)

func _on_game_lost() -> void:
	var new_record := SaveManager.submit_run(WaveManager.current_wave, WaveManager.total_kills, false)
	$UI/EndScreen.show_end(false, WaveManager.current_wave, WaveManager.total_kills, WaveManager.final_time_sec, new_record)
