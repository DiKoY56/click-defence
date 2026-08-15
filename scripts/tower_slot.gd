extends Area2D

const TOWER_COST: float = 25.0
var is_occupied: bool = false
const TowerScene: PackedScene = preload	("res://scenes/tower.tscn")

func _ready() -> void:
	input_event.connect(_on_input_event)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT \
		and event.pressed:
		try_build()
		
func try_build() -> void:
	if is_occupied:
		return
	if EconomyManager.try_spend(TOWER_COST) == false:
		print("Не хватает золотишка на башню!")
		return
		
	var tower = TowerScene.instantiate()
	get_parent().add_child(tower)
	tower.global_position = global_position
	is_occupied = true
	input_pickable = false
	$Sprite2D.visible = false
	print("Башня построена!")
