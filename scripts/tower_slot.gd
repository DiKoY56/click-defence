extends Area2D

@export var tower_types: Array[TowerData]

@onready var build_sound: AudioStreamPlayer = $BuildSound
@onready var build_menu: PanelContainer = $BuildMenu
@onready var build_buttons: Array[Button] = [%BuildButton1, %BuildButton2]

var is_occupied: bool = false

func _ready() -> void:
	input_event.connect(_on_input_event)
	build_menu.visible = false
	for i in build_buttons.size():
		build_buttons[i].pressed.connect(_on_build.bind(i))

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
		build_buttons[i].text = tower_types[i].display_name + "\n" + str(tower_types[i].cost) + " зол."
		build_buttons[i].disabled = EconomyManager.gold < tower_types[i].cost

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
