class_name TowerMenu
extends PanelContainer

@onready var title_label: Label = $VBox/TitleLabel
@onready var upgrade_button: Button = $VBox/UpgradeButton
@onready var sell_button: Button = $VBox/SellButton

var tower: Tower = null

func _ready() -> void:
	upgrade_button.pressed.connect(_on_upgrade)
	sell_button.pressed.connect(_on_sell)

func setup(t: Tower) -> void:
	tower = t
	EconomyManager.gold_changed.connect(_on_gold_changed)  # кнопки свежеют при смене золота
	refresh()
	place_at(t.global_position)

func refresh() -> void:
	if tower == null:
		return
	title_label.text = tower.data.display_name + " Lv." + str(tower.level)
	if tower.can_upgrade():
		upgrade_button.text = "Улучшить " + str(tower.get_upgrade_cost()) + " зол."
		upgrade_button.disabled = EconomyManager.gold < tower.get_upgrade_cost()
	else:
		upgrade_button.text = "Макс уровень"
		upgrade_button.disabled = true
	sell_button.text = "Продать +" + str(tower.get_sell_value()) + " зол."

func place_at(host_pos: Vector2) -> void:   # тот же кламп, что у build-меню
	var r := get_viewport_rect()
	var margin := 8.0
	reset_size()
	var desired := host_pos + Vector2(-size.x / 2.0, -size.y - 90.0)
	if desired.y < r.position.y + margin:
		desired.y = host_pos.y + 90.0
	desired.x = clampf(desired.x, r.position.x + margin, r.end.x - size.x - margin)
	desired.y = clampf(desired.y, r.position.y + margin, r.end.y - size.y - margin)
	global_position = desired

func _on_gold_changed(_g: int) -> void:
	refresh()

func _on_upgrade() -> void:
	if tower and tower.try_upgrade():
		refresh()
		place_at(tower.global_position)

func _on_sell() -> void:
	var t := tower
	tower = null
	t.sell()
