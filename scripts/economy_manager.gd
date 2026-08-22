extends Node

signal gold_changed(new_amount: int)
const START_GOLD: int = 25
var gold: int = START_GOLD

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)
	
func try_spend(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		gold_changed.emit(gold)
		return true	
	else:
		return false

func reset() -> void:
	gold = START_GOLD
	gold_changed.emit(gold)
