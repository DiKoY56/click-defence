extends Control

@export var base: Base

@onready var gold_label: Label = $GoldenLabel
@onready var health_bar: ProgressBar = $HealthBar
@onready var upgrade_button: Button = $ClickUpgradeButton

func _ready() -> void:
	EconomyManager.gold_changed.connect(_on_gold_changed)
	base.health_changed.connect(_on_base_health_changed)
	upgrade_button.pressed.connect(_on_click_upgrade_pressed)
	health_bar.max_value = base.max_health
	_on_gold_changed(EconomyManager.gold)
	_on_base_health_changed(base.health)
	refresh_shop()
	
func _on_gold_changed(new_amount: float) -> void:
	gold_label.text = "Золото: " + str(int(new_amount))
	refresh_shop()
	
func _on_base_health_changed(current: float) -> void:
	health_bar.value = current

func refresh_shop() -> void:
	upgrade_button.text = "Урон +1 - цена: " + str(UpgradeManager.get_click_upgrade_cost())
	upgrade_button.disabled = EconomyManager.gold < UpgradeManager.get_click_upgrade_cost()
	
func _on_click_upgrade_pressed() -> void:
	if UpgradeManager.buy_click_upgrade() == true:
		refresh_shop()
	else:
		print("денег нет!")
