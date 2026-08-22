extends Node

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed \
		and (event.keycode == KEY_F11 or (event.alt_pressed and event.keycode == KEY_ENTER)):
		toggle_fullscreen()

func toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
