class_name TowerData
extends Resource

@export var display_name: String = "Башня"
@export var damage: int = 5
@export var attack_speed: float = 1.0
@export var range_radius: float = 240.0
@export var cost: int = 50
@export var slow_factor: float = 1.0    # 1.0 = не замедляет
@export var slow_duration: float = 0.0  # 0 = без замедления
@export var tower_scene: PackedScene
@export var projectile_scene: PackedScene  # пусто = кот; пусто + slow>0 = лай напрямую
