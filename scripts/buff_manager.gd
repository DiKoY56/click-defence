extends Node

signal buff_applied

# --- Множители текущего забега ---
var click_damage_bonus: int = 0
var crit_chance_bonus: float = 0.0
var tower_damage_mult: float = 1.0
var attack_speed_mult: float = 1.0
var gold_mult: float = 1.0

# --- Пул баффов ---
const BUFF_POOL: Array[Dictionary] = [
	{"id": "click_damage", "name": "Крепче кулак", "desc": "+1 к урону клика"},
	{"id": "crit", "name": "Злой прищур", "desc": "+10% к шансу крита"},
	{"id": "tower_damage", "name": "Коты потолстели", "desc": "+15% к урону башен"},
	{"id": "attack_speed", "name": "Бабушки выпили кофе", "desc": "+10% к скорости атаки башен"},
	{"id": "gold", "name": "Пенсия выросла", "desc": "+20% золота с врагов"},
	{"id": "heal", "name": "Ремонт ларька", "desc": "+5 к макс. HP базы и лечение"},
	{"id": "cash", "name": "Заначка", "desc": "+50 золота сразу"},
]

func get_random_buffs(count: int) -> Array[Dictionary]:
	var pool: Array[Dictionary] = BUFF_POOL.duplicate()
	pool.shuffle()
	return pool.slice(0, count)

func apply(buff: Dictionary) -> void:
	match buff["id"]:
		"click_damage":
			click_damage_bonus += 1
		"crit":
			crit_chance_bonus += 0.10
		"tower_damage":
			tower_damage_mult *= 1.15
		"attack_speed":
			attack_speed_mult *= 1.10
		"gold":
			gold_mult *= 1.20
		"heal":
			if WaveManager.base != null:
				WaveManager.base.max_health += 5
				WaveManager.base.health = min(WaveManager.base.health + 5, WaveManager.base.max_health)
				WaveManager.base.health_changed.emit(WaveManager.base.health)
		"cash":
			EconomyManager.add_gold(50)
	buff_applied.emit()

func reset() -> void:
	click_damage_bonus = 0
	crit_chance_bonus = 0.0
	tower_damage_mult = 1.0
	attack_speed_mult = 1.0
	gold_mult = 1.0
