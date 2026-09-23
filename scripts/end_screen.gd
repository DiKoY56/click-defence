extends Control

@onready var title_label: Label = $CenterContainer/PanelContainer/VBoxContainer/TitleLabel
@onready var stats_label: Label = $CenterContainer/PanelContainer/VBoxContainer/StatsLabel
@onready var restart_button: Button = $CenterContainer/PanelContainer/VBoxContainer/RestartButton
@onready var record_label: Label = $CenterContainer/PanelContainer/VBoxContainer/RecordLabel

func _ready() -> void:
	restart_button.pressed.connect(_on_restart_pressed)

func show_end(won: bool, wave: int, kills: int, time_sec: int, new_record: bool) -> void:
	visible = true
	title_label.text = "ПОБЕДА!" if won else "ПОРАЖЕНИЕ: ВСЁ ПИВО ВЫСОСАЛИ"
	title_label.add_theme_color_override("font_color", Color.GREEN if won else Color.RED)
	stats_label.text = "Волна: " + str(wave) + " | Убито: " + str(kills) + " | Время: " + format_time(time_sec)
	record_label.text = ("НОВЫЙ РЕКОРД! " if new_record else "") + "Рекорд: волна " + str(SaveManager.best_wave)
	record_label.add_theme_color_override("font_color", Color.YELLOW if new_record else Color(0.7, 0.7, 0.7))
	
func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

func format_time(total_sec: int) -> String:
	@warning_ignore("integer_division")
	var minutes: int = total_sec / 60
	var seconds: int = total_sec % 60
	return str(minutes) + ":" + str(seconds).pad_zeros(2)
