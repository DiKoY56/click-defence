extends Node2D

const MAPS: Array[PackedScene] = [preload("res://scenes/maps/map_1.tscn"), preload("res://scenes/maps/map_2.tscn"), preload("res://scenes/maps/map_3.tscn")]

func _ready() -> void:
	var map_scene: PackedScene = MAPS.pick_random()
	var map: Node2D = map_scene.instantiate()
	$MapHolder.add_child(map)
	$EnemySpawner.path = map.enemy_path
	$EnemySpawner.base = map.base
	$UI/HUD.setup(map.base)
	$EnemySpawner.start_spawning()
