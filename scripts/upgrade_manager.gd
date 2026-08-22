extends Node

const BASE_COST: int = 10
const COST_GROWTH: float = 1.5
const DAMAGE_STEP: int = 1

#CRIT
const CRIT_CHANCE: float = 0.1
const CRIT_MULTIPLIER: int = 3

var click_level: int = 0

func is_crit() -> bool:
	return randf() < CRIT_CHANCE

func get_click_damage() -> int:
	var damage = 1 + DAMAGE_STEP * click_level
	return damage

func get_click_upgrade_cost() -> int:
	#var cost = BASE_COST * pow(COST_GROWTH,click_level)
	var cost = int(ceil(BASE_COST * pow(COST_GROWTH, click_level)))
	return cost

func buy_click_upgrade() -> bool:
	if EconomyManager.try_spend(get_click_upgrade_cost()) == true:
		click_level += 1
		return true
	else: return false
	
func reset() -> void:
	click_level = 0
