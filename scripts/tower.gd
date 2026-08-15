extends Node2D
@export var damage: float = 5.0
@export var attack_speed: float = 1.0

@onready var shoot_timer: Timer = $ShootTimer
@onready var range_area: Area2D = $RangeArea

var targets: Array = []

func _ready() -> void:
	#подключить сигналы зоны
	range_area.area_entered.connect(_on_entered)
	range_area.area_exited.connect(_on_exited)
	shoot_timer.wait_time = 1.0 / attack_speed
	shoot_timer.timeout.connect(_on_shoot_timer)
	
func _on_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		targets.append(area)

func _on_exited(area: Area2D) -> void:
	targets.erase(area)           # убрать из списка

func _on_shoot_timer() -> void:
	var best = null
	var best_progress: int = -1
	for t in targets:
		if is_instance_valid(t):
			if t.target_index > best_progress:   # чем больше индекс, тем ближе к базе
				best_progress = t.target_index
				best = t
	if best != null:
		best.take_damage(damage)			
		
