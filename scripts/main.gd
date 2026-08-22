extends Node2D

const MAPS: Array[PackedScene] = [preload("res://scenes/maps/map_1.tscn"), preload("res://scenes/maps/map_2.tscn"), preload("res://scenes/maps/map_3.tscn")]

func _ready() -> void:
	UpgradeManager.reset()
	EconomyManager.reset()
	WaveManager.reset()
	
	var map_scene: PackedScene = MAPS.pick_random()
	var map: Node2D = map_scene.instantiate()
	$MapHolder.add_child(map)
	$EnemySpawner.path = map.enemy_path
	$EnemySpawner.base = map.base
	$UI/HUD.setup(map.base)
	
	WaveManager.game_won.connect(_on_game_won)
	WaveManager.game_lost.connect(_on_game_lost)
	
	WaveManager.setup($EnemySpawner, map.base)  
	WaveManager.start_game() 

func _on_game_won() -> void:
	$UI/EndScreen.show_end(true, WaveManager.TOTAL_WAVES, WaveManager.total_kills, WaveManager.final_time_sec)

func _on_game_lost() -> void:
	$UI/EndScreen.show_end(false, WaveManager.current_wave, WaveManager.total_kills, WaveManager.final_time_sec)
