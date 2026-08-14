extends Node

const BASE_COST = 10.0
const COST_GROWTH = 1.5
const DAMAGE_STEP = 1.0

var click_level: int = 0

func get_click_damage() -> float:
	var damage = 1.0 + DAMAGE_STEP * click_level
	return damage

func get_click_upgrade_cost() -> float:
	var cost = BASE_COST * pow(COST_GROWTH,click_level)
	return cost

func buy_click_upgrade() -> bool:
	if EconomyManager.try_spend(get_click_upgrade_cost()) == true:
		click_level += 1
		return true
	else: return false
	
	
	
