extends Node

signal gold_changed(new_amount: float)
var gold: float = 0.0

func add_gold(amount: float) -> void:
	gold += amount
	gold_changed.emit(gold)
	print("Червонец: ", gold)
	
func try_spend(amount: float) -> bool:
	if gold >= amount:
		gold -= amount
		gold_changed.emit(gold)
		return true	
	else:
		return false
