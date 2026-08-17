class_name FloatingText
extends Node2D

@onready var label: Label = $Label

#func _ready() -> void:
	
func setup(text: String) -> void:
	label.text = text
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", Vector2.UP * 300, 1.0)
	tween.tween_property(label, "modulate:a", 0, 1.0)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
	
