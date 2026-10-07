class_name MetaUpgradeData
extends Resource

@export var id: String = "upgrade_id"
@export var display_name: String = "Название"
@export var description: String = "Описание эффекта"
@export var max_level: int = 5
@export var base_cost: int = 50
@export var cost_growth: float = 1.8

# Тип эффекта (для применения в игре)
enum EffectType {
	START_GOLD,           # +N золота в начале забега
	CLICK_DAMAGE_BONUS,   # +N к базовому урону клика
	BASE_HP_BONUS,        # +N к макс. HP базы
	TOWER_COST_DISCOUNT,  # -N% к стоимости всех башен
	CRIT_CHANCE_BONUS,    # +N% к шансу крита
}
@export var effect_type: EffectType
@export var effect_value_per_level: float = 1.0

func get_cost(level: int) -> int:
	return int(ceil(base_cost * pow(cost_growth, level)))

func get_effect_value(level: int) -> float:
	return effect_value_per_level * level
