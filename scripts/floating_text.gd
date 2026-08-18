class_name FloatingText
extends Node2D

@onready var label: Label = $Label
const CRIT_FONT: Font = preload("res://assets/fonts/PressStart2P-Regular.ttf")
	
func setup(text: String, color: Color = Color.WHITE, is_crit:bool = false) -> void:
	label.text = text
	label.add_theme_color_override("font_color", color)
	if is_crit:
		label.add_theme_font_size_override("font_size", 28)
		label.add_theme_font_override("font_name", CRIT_FONT)
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", Vector2.UP * 300, 1.0)
	tween.tween_property(label, "modulate:a", 0, 1.0)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
	
