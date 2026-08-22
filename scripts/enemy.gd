class_name Enemy
extends Area2D

signal died

# --- Настройки (видны в инспекторе) ---
@export var path: Path2D 
@export var base:Base

var max_health: int = 8
var speed: float = 120.0
var damage_to_base: int = 5
var gold_reward: int = 5

const text_scene: PackedScene = preload("res://scenes/effects/floating_text.tscn")
const DeathSound: AudioStream = preload("res://assets/audio/death.wav")
const HitSound: AudioStream = preload("res://assets/audio/hit.wav")
const CritHitSound: AudioStream = preload("res://assets/audio/crit.wav")

# --- Внутреннее состояние ---
var health: int
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
		died.emit()
		queue_free()

# --- логика кликов ---
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT \
		and event.pressed:
		get_viewport().set_input_as_handled()
		var damage := UpgradeManager.get_click_damage()
		var color: Color = Color.WHITE
		var is_critical: bool = UpgradeManager.is_crit()
		if is_critical:
			damage *= UpgradeManager.CRIT_MULTIPLIER
			color = Color.RED
		take_damage(damage, color, is_critical)
		play_hit_sound(is_critical)

func take_damage(amount: int, color: Color = Color.WHITE, crit: bool = false) -> void:
	if health <= 0:
		return
	health -= amount
	var str_amount = str(amount)
	var text_damage: FloatingText = text_scene.instantiate() as FloatingText
	var main_scene = get_tree().current_scene
	main_scene.add_child(text_damage)
	text_damage.setup(str_amount, color, crit)
	text_damage.global_position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
	
	print("Попадание! Осталось HP: ", health)
	if health <= 0:
		die()

func die() -> void:
	EconomyManager.add_gold(gold_reward)
	play_death_sound()
	died.emit()
	queue_free()

func play_death_sound() -> void:
	var player := AudioStreamPlayer2D.new()
	player.stream = DeathSound
	player.position = global_position
	player.pitch_scale = randf_range(0.90, 1.05)
	player.volume_db = -8
	get_tree().current_scene.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func play_hit_sound(is_crit: bool = false) -> void:
	var player := AudioStreamPlayer2D.new()
	if is_crit:
		player.stream = CritHitSound
		player.pitch_scale = randf_range(0.90, 1.05)
		player.volume_db = -8
	else:
		player.stream = HitSound
		player.pitch_scale = randf_range(0.90, 1.05)
		player.volume_db = -5
	player.position = global_position
	get_tree().current_scene.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
	
func setup(data: EnemyData) -> void:
	max_health = data.max_health
	speed = data.speed
	gold_reward = data.gold_reward
	damage_to_base = data.damage_to_base
	$Sprite2D.scale *= data.visual_scale   # умножаем базовый масштаб сцены (3,3)
	$Sprite2D.modulate = data.tint
