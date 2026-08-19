extends Node

signal gold_changed(new_amount: int)
var gold: int = 100

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
