extends Area2D

@export var tower_types: Array[TowerData]

@onready var build_sound: AudioStreamPlayer = $BuildSound
@onready var build_menu: PanelContainer = $BuildMenu
@onready var menu_box: VBoxContainer = $BuildMenu/VBoxContainer

const UI_FONT: Font = preload("res://assets/fonts/PressStart2P-Regular.ttf")

var is_occupied: bool = false
var menu_buttons: Array[Button] = []

func _ready() -> void:
	input_event.connect(_on_input_event)
	build_menu.visible = false
	_create_buttons()

func _create_buttons() -> void:
	# по кнопке на тип башни — меню соберётся само под любое число типов
	for i in tower_types.size():
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(260, 64)
		btn.add_theme_font_override("font", UI_FONT)
		btn.add_theme_font_size_override("font_size", 10)
		btn.pressed.connect(_on_build.bind(i))
		menu_box.add_child(btn)
		menu_buttons.append(btn)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT \
		and event.pressed:
		if not is_occupied:
			toggle_build_menu()

func toggle_build_menu() -> void:
	build_menu.visible = not build_menu.visible
	if build_menu.visible:
		refresh_buttons()

func refresh_buttons() -> void:
	for i in tower_types.size():
		menu_buttons[i].text = tower_types[i].display_name + "\n" + str(tower_types[i].cost) + " зол."
		menu_buttons[i].disabled = EconomyManager.gold < tower_types[i].cost

func _on_build(index: int) -> void:
	var d: TowerData = tower_types[index]
	if is_occupied or not EconomyManager.try_spend(d.cost):
		return
	var tower: Tower = d.tower_scene.instantiate() as Tower
	get_parent().add_child(tower)
	tower.global_position = global_position
	tower.setup(d)
	is_occupied = true
	input_pickable = false
	$Sprite2D.visible = false
	build_menu.visible = false
	build_sound.play()
