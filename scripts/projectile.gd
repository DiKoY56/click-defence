class_name Projectile
extends Node2D

var target = null
var damage: int = 5          # башня передаёт свой урон
var speed: float = 500.0
var fly_to: Vector2          # точка полёта: живая цель или её последняя позицияэ
 	
@export var spins_per_second: float = 1.0   # оборотов в секунду

func _ready() -> void:
	if is_instance_valid(target):
		fly_to = target.global_position
	else:
		queue_free()

func _process(delta: float) -> void:
	# пока цель жива доворачиваем на неё
	if is_instance_valid(target):
		fly_to = target.global_position

	var distance: float = global_position.distance_to(fly_to)
	var step: float = speed * delta

	if distance <= step:
		# ДОЛЕТЕЛ: урон только если цель ещё жива
		if is_instance_valid(target):
			target.take_damage(damage)   # цифра всплывёт ровно в момент попадания
		queue_free()
		return

	var direction: Vector2 = (fly_to - global_position).normalized()
	global_position += direction * step
	
	rotation += TAU * spins_per_second * delta

#func _draw() -> void:
	#draw_circle(Vector2.ZERO, 5.0, Color.YELLOW)
