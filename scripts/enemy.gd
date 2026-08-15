class_name Enemy
extends Area2D

# --- Настройки (видны в инспекторе) ---
@export var max_health: float = 6.0
@export var speed: float = 120.0
@export var path: Path2D 
@export var base:Base
@export var damage_to_base: float = 5.0
@export var gold_reward: float = 2.0

# --- Внутреннее состояние ---
var health: float
var points: PackedVector2Array  # массив точек пути
var target_index: int = 0       # к какой точке сейчас идём

func _ready() -> void:
	health = max_health
	input_event.connect(_on_input_event)
	add_to_group("enemies")

	
	if path == null or path.curve == null:
		push_error("Враг: не задан путь (path)!")
		set_process(false)
		return

	#  точки кривой — много маленьких отрезков, по которым удобно идти
	points = path.curve.get_baked_points()
	if points.is_empty():
		push_error("Враг: путь пустой!")
		return

	global_position = points[0]  # появляемся в начале пути
	target_index = 1             # идём ко второй точке
	
	if base == null:
		push_error("Враг: а где база то?!")
		set_process(false)
		return
		
#вызывается КАЖДЫЙ кадр
func _process(delta: float) -> void:
	if target_index < 1 or target_index >= points.size():
		return  # путь не готов или уже пройден

	var target: Vector2 = points[target_index]
	var step: float = speed * delta              # сколько прошли за этот кадр
	var distance: float = global_position.distance_to(target)

	if distance <= step:
		# Дошли до точки — переключаемся на следующую
		global_position = target
		target_index += 1
		if target_index >= points.size():
			_reach_base()
	else:
		# Идём в сторону цели
		var direction: Vector2 = (target - global_position).normalized()
		global_position += direction * step

func _reach_base() -> void:
		base.take_damage(damage_to_base)
		print("Враг дошёл до базы!")
		queue_free()

# --- логика кликов ---
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT \
		and event.pressed:
		take_damage(UpgradeManager.get_click_damage())

func take_damage(amount: float) -> void:
	if health <= 0.0:
		return
	health -= amount
	print("Попадание! Осталось HP: ", health)
	if health <= 0.0:
		die()

func die() -> void:
	EconomyManager.add_gold(gold_reward)
	print("Враг погиб")
	queue_free()
