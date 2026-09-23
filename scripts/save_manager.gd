extends Node

signal settings_changed

const SAVE_PATH := "user://save.cfg"

# --- экономика престижа (валюта за перманентные апгрейды) ---
const POINTS_PER_WAVE := 8
const KILL_FACTOR := 0.5
const WIN_BONUS := 50

# --- настройки ---
var fullscreen: bool = true
var volume: float = 1.0        # 0..1
# --- статистика ---
var best_wave: int = 0
var best_kills: int = 0
var runs: int = 0
var wins: int = 0
# --- валюта ---
var prestige_points: int = 0

func _ready() -> void:
	load_game()
	if not OS.has_feature("editor"):
		_apply_window_mode()   # старт экспорта — по сейву; редактор остаётся оконным
	_apply_volume()

func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return   # первого сейва ещё нет — живём с дефолтами
	fullscreen = cfg.get_value("settings", "fullscreen", fullscreen)
	volume = cfg.get_value("settings", "volume", volume)
	best_wave = cfg.get_value("stats", "best_wave", best_wave)
	best_kills = cfg.get_value("stats", "best_kills", best_kills)
	runs = cfg.get_value("stats", "runs", runs)
	wins = cfg.get_value("stats", "wins", wins)
	prestige_points = cfg.get_value("stats", "prestige_points", prestige_points)

func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("settings", "fullscreen", fullscreen)
	cfg.set_value("settings", "volume", volume)
	cfg.set_value("stats", "best_wave", best_wave)
	cfg.set_value("stats", "best_kills", best_kills)
	cfg.set_value("stats", "runs", runs)
	cfg.set_value("stats", "wins", wins)
	cfg.set_value("stats", "prestige_points", prestige_points)
	cfg.save(SAVE_PATH)

# --- применение настроек ---
func _apply_window_mode() -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)

func _apply_volume() -> void:
	var db := linear_to_db(volume) if volume > 0.0 else -80.0
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)

func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_apply_window_mode()   # ВСЕГДА: явное действие пользователя, в редакторе тоже
	save_game()
	settings_changed.emit()

func set_volume(value: float) -> void:
	volume = clampf(value, 0.0, 1.0)
	_apply_volume()
	save_game()
	settings_changed.emit()

# --- очки за один забег (прозрачная формула) ---
func _run_points(wave: int, kills: int, won: bool) -> int:
	var points := wave * POINTS_PER_WAVE + int(kills * KILL_FACTOR)
	if won:
		points += WIN_BONUS
	return points

func submit_run(wave: int, kills: int, won: bool) -> bool:   # вернёт true, если новый рекорд
	runs += 1
	if won:
		wins += 1
	var new_record := wave > best_wave
	if new_record:
		best_wave = wave
		best_kills = kills
	prestige_points += _run_points(wave, kills, won)   # ← капают очки
	save_game()
	return new_record
