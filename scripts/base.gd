class_name Base
extends Node2D

signal health_changed(current: int)
signal destroyed

@export var max_health: int = 20

@onready var sprite: AnimatedSprite2D = $Sprite

const DamageBaseSound: AudioStream = preload("res://assets/audio/damage_base.wav")

var health: int

func _ready() -> void:
	health = max_health

func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health = max(health - amount , 0)
	play_damage_sound()
	play_hit_reaction()
	print("HP базы: ", health)
	health_changed.emit(health)
	if health <= 0:
		die()

func die() -> void:
	sprite.stop()
	sprite.modulate= Color.RED
	destroyed.emit()
	
func play_damage_sound() -> void:
	var player := AudioStreamPlayer2D.new()
	player.stream = DamageBaseSound
	player.position = global_position
	player.pitch_scale = randf_range(0.90, 1.05)
	player.volume_db = -8
	get_tree().current_scene.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func play_hit_reaction() -> void:
	var base_scale := sprite.scale
	var tween := create_tween()
	tween.tween_property(sprite, "scale", base_scale * 0.94, 0.06)
	tween.tween_property(sprite, "scale", base_scale, 0.06)
