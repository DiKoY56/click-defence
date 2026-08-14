class_name Base
extends Node2D

signal health_changed(current: float)
signal destroyed

@export var max_health: float = 20.0

var health: float

func _ready() -> void:
	health = max_health

func take_damage(amount: float) -> void:
	if health <= 0.0:
		return
	health = max(health - amount , 0.0)
	print("HP базы: ", health)
	health_changed.emit(health)
	if health <= 0.0:
		die()

func die() -> void:
	$Sprite2D.modulate=Color.RED
	print("База уничтожена")
	destroyed.emit()
	
