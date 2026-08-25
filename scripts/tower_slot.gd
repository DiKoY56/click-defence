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
	add_to_group("tower_slots")
	build_menu.visible = false
	_create_buttons()
	build_menu.z_index = 100

func _create_buttons() -> void:
	for i in tower_types.size():
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(260, 64)
		btn.add_theme_font_override("font", UI_FONT)
		btn.add_theme_font_size_override("font_size", 10)
		btn.pressed.connect(_on_build.bind(i))
		menu_box.add_child(btn)
		menu_buttons.append(btn)
	build_menu.reset_size()
	_position_menu()

func _position_menu() -> void:
	var r := get_viewport_rect()      # видимая область в координатах мира (0..1920, 0..1080)
	var margin := 8.0
	var size := build_menu.size
	var desired := global_position + Vector2(-size.x / 2.0, -size.y - 80.0)
	# не влезло сверху ставим под слот
	if desired.y < r.position.y + margin:
		desired.y = global_position.y + 80.0
	# и в любом случае не выпускаем за экран
	desired.x = clampf(desired.x, r.position.x + margin, r.end.x - size.x - margin)
	desired.y = clampf(desired.y, r.position.y + margin, r.end.y - size.y - margin)
	build_menu.global_position = desired

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT \
		and event.pressed:
		if is_occupied:
			return   # занятой слот = «пустое место»: клик провалится в _unhandled_input и закроет меню
		get_viewport().set_input_as_handled()   # защищаем свой клик от _unhandled_input
		if build_menu.visible:
			close_menu()
		else:
			open_menu()

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
	close_menu()
	build_sound.play()
	
func open_menu() -> void:
	for slot in get_tree().get_nodes_in_group("tower_slots"):
		if slot != self:
			slot.close_menu()   # одновременно открыто только одно меню
	build_menu.visible = true
	refresh_buttons()

func close_menu() -> void:
	build_menu.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT \
		and event.pressed \
		and build_menu.visible:
		close_menu()
