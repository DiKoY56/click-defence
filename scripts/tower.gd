class_name Tower
extends Node2D

var data: TowerData
var damage: int = 5
var attack_speed: float = 1.0
var targets: Array = []
var current_target = null

@export var show_range: bool = true   # тумблер для отладки и будущего UX
@export var shoot_animation: String = "shoot"  # у собаки будет "attack"
@export var throw_frame: int = 6               # у собаки кадр лая

@onready var shoot_timer: Timer = $ShootTimer
@onready var range_area: Area2D = $RangeArea
@onready var range_shape: CircleShape2D = $RangeArea/CollisionShape2D.shape
@onready var shoot_sound: AudioStreamPlayer2D = $ShootSound
@onready var sprite: AnimatedSprite2D = $Sprite

const ProjectileScene: PackedScene = preload("res://scenes/effects/projectile.tscn")

func _ready() -> void:
	range_area.area_entered.connect(_on_entered)
	range_area.area_exited.connect(_on_exited)
	update_attack_speed()                                  
	BuffManager.buff_applied.connect(update_attack_speed)  #стоящие башни тоже ускорятся
	shoot_timer.timeout.connect(_on_shoot_timer)
	sprite.frame_changed.connect(_on_frame_changed)
	sprite.animation_finished.connect(_on_animation_finished)
	
func update_attack_speed() -> void:
	shoot_timer.wait_time = 1.0 / (attack_speed * BuffManager.attack_speed_mult)
		
func _on_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		targets.append(area)

func _on_exited(area: Area2D) -> void:
	targets.erase(area)           # убрать из списка

func _on_shoot_timer() -> void:
	if sprite.animation == shoot_animation:
		return  # Уже в замахе ждём окончания
	var best = find_best_target()
	if best != null:
		current_target = best
		sprite.play(shoot_animation)

func _draw() -> void:
	if not show_range:
		return
	# полупрозрачная заливка + видимая граница
	draw_circle(Vector2.ZERO, range_shape.radius, Color(0.3, 0.7, 1.0, 0.12))
	draw_arc(Vector2.ZERO, range_shape.radius, 0.0, TAU, 48, Color(0.3, 0.7, 1.0, 0.6), 2.0)

func shoot_projectile() -> void:
	if not is_instance_valid(current_target) or current_target not in targets:
		return
	var projectile: Projectile = ProjectileScene.instantiate() as Projectile
	projectile.target = current_target    # сначала ссылки
	projectile.damage = int(round(damage * BuffManager.tower_damage_mult))      #  урон
	get_tree().current_scene.add_child(projectile)  # потом в дерево
	projectile.global_position = global_position
	shoot_sound.pitch_scale = randf_range(0.8, 1.1)
	shoot_sound.play()

func _on_frame_changed() -> void:
	if sprite.animation == shoot_animation and sprite.frame == throw_frame:
		# Подмена цели, если текущая невалидна или вышла из радиуса
		if not is_instance_valid(current_target) or current_target not in targets:
			current_target = find_best_target()
		# Проверяем, есть ли цель
		if is_instance_valid(current_target) and current_target in targets:
			attack_target()
			# Выстрелили — ждём animation_finished для возврата в idle
		else:
			# Нет цели — сразу возвращаемся в idle
			sprite.play("idle")

func attack_target() -> void:
	var dmg: int = int(round(damage * BuffManager.tower_damage_mult))
	if data and data.slow_duration > 0.0 and data.projectile_scene == null:
		# СОБАКА: лает эффект сразу на цели, снаряда нет
		if dmg > 0:
			current_target.take_damage(dmg)
		current_target.apply_slow(data.slow_factor, data.slow_duration)
	else:
		# БАБУШКА (и будущие): снаряд
		var scene: PackedScene = data.projectile_scene if data and data.projectile_scene else ProjectileScene
		var projectile: Projectile = scene.instantiate() as Projectile
		projectile.target = current_target
		projectile.damage = dmg
		get_tree().current_scene.add_child(projectile)
		projectile.global_position = global_position
	shoot_sound.pitch_scale = randf_range(0.8, 1.1)
	shoot_sound.play()

func _on_animation_finished() -> void:
	if sprite.animation == shoot_animation:
		sprite.play("idle")

func find_best_target():
	var best = null
	var best_progress: int = -1
	for t in targets:
		if is_instance_valid(t):
			if t.target_index > best_progress:
				best_progress = t.target_index
				best = t
	return best
	
func _process(delta: float) -> void:
	if is_instance_valid(current_target):
		var direction = current_target.global_position - global_position
		sprite.flip_h = direction.x > 0  # true = отразить, если враг слева

func setup(d: TowerData) -> void:
	data = d
	damage = d.damage
	attack_speed = d.attack_speed
	range_shape.radius = d.range_radius
	queue_redraw()          # перерисовать круг радиуса 
	update_attack_speed()
