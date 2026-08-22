extends Control

@onready var gold_label: Label = $GoldenLabel
@onready var health_bar: ProgressBar = $HealthBar
@onready var upgrade_button: Button = $ClickUpgradeButton
@onready var purchase_sound: AudioStreamPlayer = $PurchaseSound
@onready var wave_label: Label = $WaveLabel  # новый Label в HUD
@onready var notification_label: Label = $NotificationLabel  # большой Label по центру

var base: Base

func _ready() -> void:
	EconomyManager.gold_changed.connect(_on_gold_changed)
	#base.health_changed.connect(_on_base_health_changed)
	upgrade_button.pressed.connect(_on_click_upgrade_pressed)
	#health_bar.max_value = base.max_health
	_on_gold_changed(EconomyManager.gold)
	#_on_base_health_changed(base.health)
	refresh_shop()
	
func _on_gold_changed(new_amount: int) -> void:
	gold_label.text = "Золото: " + str(new_amount)
	refresh_shop()
	
func _on_base_health_changed(current: int) -> void:
	health_bar.value = current

func refresh_shop() -> void:
	upgrade_button.text = "Урон +1 - цена: " + str(UpgradeManager.get_click_upgrade_cost())
	upgrade_button.disabled = EconomyManager.gold < UpgradeManager.get_click_upgrade_cost()
	
func _on_click_upgrade_pressed() -> void:
	if UpgradeManager.buy_click_upgrade() == true:
		purchase_sound.play()
		refresh_shop()
	else:
		print("денег нет!")

func setup(new_base: Base) -> void:
	base = new_base
	base.health_changed.connect(_on_base_health_changed)
	WaveManager.wave_started.connect(_on_wave_started)
	WaveManager.boss_incoming.connect(_on_boss_incoming)
	health_bar.max_value = base.max_health
	_on_base_health_changed(base.health)
	refresh_shop()

func _on_wave_started(wave_number: int) -> void:
	wave_label.text = "Волна: " + str(wave_number)
	show_notification("Волна " + str(wave_number) + " началась!")

func _on_boss_incoming() -> void:
	show_notification("БОСС ПРИБЛИЖАЕТСЯ!")

func show_notification(text: String) -> void:
	notification_label.text = text
	notification_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(notification_label, "modulate:a", 0.0, 2.0)
