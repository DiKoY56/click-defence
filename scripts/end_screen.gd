extends Control

@onready var title_label: Label = $CenterContainer/PanelContainer/VBoxContainer/TitleLabel
@onready var stats_label: Label = $CenterContainer/PanelContainer/VBoxContainer/StatsLabel
@onready var restart_button: Button = $CenterContainer/PanelContainer/VBoxContainer/RestartButton

func _ready() -> void:
	restart_button.pressed.connect(_on_restart_pressed)

func show_end(won: bool, wave: int, kills: int, time_sec: int) -> void:
	visible = true
	title_label.text = "ПОБЕДА!" if won else "ПОРАЖЕНИЕ: ВСЁ ПИВО ВЫСОСАЛИ"
	title_label.add_theme_color_override("font_color", Color.GREEN if won else Color.RED)
	stats_label.text = "Волна: " + str(wave) + " | Убито: " + str(kills) + " | Время: " + format_time(time_sec)

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

func format_time(total_sec: int) -> String:
	@warning_ignore("integer_division")
	var minutes: int = total_sec / 60
	var seconds: int = total_sec % 60
	return str(minutes) + ":" + str(seconds).pad_zeros(2)
