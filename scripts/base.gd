class_name Base
extends Node2D

signal health_changed(current: int)
signal destroyed

@export var max_health: int = 20

var health: int

func _ready() -> void:
	health = max_health

func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health = max(health - amount , 0)
	print("HP базы: ", health)
	health_changed.emit(health)
	if health <= 0:
		die()

func die() -> void:
	$Sprite2D.modulate=Color.RED
	print("База уничтожена")
	destroyed.emit()
	
