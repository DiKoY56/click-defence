extends Control

@onready var buttons: Array[Button] = [%BuffButton1, %BuffButton2, %BuffButton3]

var choices: Array[Dictionary] = []

func _ready() -> void:
	for i in 3:
		buttons[i].pressed.connect(_on_choice.bind(i))

func show_choices() -> void:
	visible = true
	choices = BuffManager.get_random_buffs(3)
	for i in 3:
		buttons[i].text = choices[i]["name"] + "\n\n" + choices[i]["desc"]

func _on_choice(index: int) -> void:
	BuffManager.apply(choices[index])
	visible = false
	WaveManager.proceed_to_next_wave()
