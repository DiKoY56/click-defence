extends Control
@onready var menu_panel: CenterContainer = $CenterContainer
func _ready() -> void:
	%PlayButton.pressed.connect(_on_play_pressed)
	%SettingsButton.pressed.connect(_on_settings_pressed)
	%QuitButton.pressed.connect(_on_quit_pressed)
	%BackButton.pressed.connect(_on_back_pressed)
	%FullscreenCheck.toggled.connect(func(p: bool) -> void: SaveManager.set_fullscreen(p))
	%VolumeSlider.value_changed.connect(func(v: float) -> void: SaveManager.set_volume(v))
	%FullscreenCheck.button_pressed = SaveManager.fullscreen
	%VolumeSlider.value = SaveManager.volume
	_refresh_record_label()
	
func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_settings_pressed() -> void:
	%SettingsCenter.visible = true
	menu_panel.visible = false
	
func _on_quit_pressed() -> void:
	get_tree().quit()
	
func _on_back_pressed() -> void:
	%SettingsCenter.visible = false
	menu_panel.visible = true
	
func _refresh_record_label() -> void:
	if SaveManager.best_wave > 0:
		%RecordLabel.text = "Рекорд: волна " + str(SaveManager.best_wave) + " | Забегов: " + str(SaveManager.runs)
	else:
		%RecordLabel.text = "Рекорда пока нет — исправь это!"
