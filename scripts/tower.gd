class_name Tower
extends Node2D

var data: TowerData
var level: int = 1
var invested: int = 0
var home_slot: TowerSlot = null
var menu: TowerMenu = null
var level_label: Label = null
var base_sprite_scale: Vector2 = Vector2.ONE
var targets: Array = []
var current_target = null

@export var show_range: bool = true
@export var shoot_animation: String = "shoot"
@export var throw_frame: int = 6

@onready var shoot_timer: Timer = $ShootTimer
@onready var range_area: Area2D = $RangeArea
@onready var range_shape: CircleShape2D = $RangeArea/CollisionShape2D.shape
@onready var shoot_sound: AudioStreamPlayer2D = $ShootSound
@onready var sprite: AnimatedSprite2D = $Sprite

const ProjectileScene: PackedScene = preload("res://scenes/effects/projectile.tscn")
const TowerMenuScene: PackedScene = preload("res://scenes/ui/tower_menu.tscn")
const UI_FONT: Font = preload("res://assets/fonts/PressStart2P-Regular.ttf")
const SELL_REFUND: float = 0.7

func _ready() -> void:
	add_to_group("towers")
	base_sprite_scale = sprite.scale
	range_area.area_entered.connect(_on_entered)
	range_area.area_exited.connect(_on_exited)
	BuffManager.buff_applied.connect(update_attack_speed)
	shoot_timer.timeout.connect(_on_shoot_timer)
	sprite.frame_changed.connect(_on_frame_changed)
	sprite.animation_finished.connect(_on_animation_finished)
	_make_click_area()

func setup(d: TowerData) -> void:
	data = d
	invested = d.cost
	range_shape.radius = d.range_radius
	queue_redraw()
	update_attack_speed()

# ---------- эффективные статы: база × уровень × баффы ----------
func _power_mult() -> float:
	return data.power_mult_per_level[level - 1]

func _speed_mult() -> float:
	return data.speed_mult_per_level[level - 1]

func get_damage() -> int:
	return int(round(data.damage * _power_mult()))

func get_attack_speed() -> float:
	return data.attack_speed * _speed_mult()

func get_slow_factor() -> float:
	if data.slow_duration <= 0.0:
		return 1.0
	return clampf(1.0 - (1.0 - data.slow_factor) * _power_mult(), 0.2, 1.0)

func update_attack_speed() -> void:
	if data == null:
		return
	shoot_timer.wait_time = 1.0 / (get_attack_speed() * BuffManager.attack_speed_mult)

# ---------- прокачка / продажа ----------
func can_upgrade() -> bool:
	return level < data.max_level

func get_upgrade_cost() -> int:
	return data.upgrade_costs[level - 1]

func get_sell_value() -> int:
	return int(round(invested * SELL_REFUND))

func try_upgrade() -> bool:
	if not can_upgrade():
		return false
	if not EconomyManager.try_spend(get_upgrade_cost()):
		return false
	invested += get_upgrade_cost()
	level += 1
	update_attack_speed()
	_update_level_label()
	var tw := create_tween()   # сочный «поп» масштаба
	tw.tween_property(sprite, "scale", base_sprite_scale * 1.15, 0.08)
	tw.tween_property(sprite, "scale", base_sprite_scale, 0.08)
	return true

func sell() -> void:
	close_menu()
	EconomyManager.add_gold(get_sell_value())
	if home_slot:
		home_slot.free_slot()
	queue_free()

func _update_level_label() -> void:
	if level_label == null:
		level_label = Label.new()
		level_label.add_theme_font_override("font", UI_FONT)
		level_label.add_theme_font_size_override("font_size", 12)
		level_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
		level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # не мешает кликам
		level_label.z_index = 10                                # не перекрывается ничем
		add_child(level_label)
	level_label.text = "Lv" + str(level)
	level_label.reset_size()   # ← размер = ровно по тексту
	level_label.position = Vector2(-level_label.size.x / 2.0, -96.0)

# ---------- клик по башне и меню ----------
func _make_click_area() -> void:   # создаём кодом, чтобы не править 3 сцены
	var area := Area2D.new()
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 48.0
	col.shape = shape
	area.add_child(col)
	area.input_event.connect(_on_click_event)
	add_child(area)

func _on_click_event(_vp: Node, event: InputEvent, _idx: int) -> void:
	if event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT \
		and event.pressed:
		get_viewport().set_input_as_handled()
		if menu:
			close_menu()
		else:
			open_menu()

func open_menu() -> void:
	for s in get_tree().get_nodes_in_group("tower_slots"):
		s.close_menu()
	for t in get_tree().get_nodes_in_group("towers"):
		if t != self:
			t.close_menu()
	menu = TowerMenuScene.instantiate()
	get_tree().current_scene.add_child(menu)
	menu.setup(self)

func close_menu() -> void:
	if menu:
		menu.queue_free()
		menu = null

func _unhandled_input(event: InputEvent) -> void:
	if menu and event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT \
		and event.pressed:
		close_menu()

# ---------- бой (как было, но через геттеры) ----------
func _on_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		targets.append(area)

func _on_exited(area: Area2D) -> void:
	targets.erase(area)

func _on_shoot_timer() -> void:
	if sprite.animation == shoot_animation:
		return
	var best = find_best_target()
	if best != null:
		current_target = best
		sprite.play(shoot_animation)

func _draw() -> void:
	if not show_range:
		return
	draw_circle(Vector2.ZERO, range_shape.radius, Color(0.3, 0.7, 1.0, 0.12))
	draw_arc(Vector2.ZERO, range_shape.radius, 0.0, TAU, 48, Color(0.3, 0.7, 1.0, 0.6), 2.0)

func _on_frame_changed() -> void:
	if sprite.animation == shoot_animation and sprite.frame == throw_frame:
		if not is_instance_valid(current_target) or current_target not in targets:
			current_target = find_best_target()
		if is_instance_valid(current_target) and current_target in targets:
			attack_target()
		else:
			sprite.play("idle")

func attack_target() -> void:
	var dmg: int = int(round(get_damage() * BuffManager.tower_damage_mult))
	if data and data.slow_duration > 0.0 and data.projectile_scene == null:
		if dmg > 0:
			current_target.take_damage(dmg)
		current_target.apply_slow(get_slow_factor(), data.slow_duration)
	else:
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
		sprite.flip_h = direction.x > 0
