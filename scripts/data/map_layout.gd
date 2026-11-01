class_name MapLayout
extends Resource

# Точки кривой пути врагов. points[0] = точка спавна (на краю карты),
# последняя точка приводит к базе.
@export var path_points: PackedVector2Array = PackedVector2Array()

# Центр базы (ларёк). Обычно чуть дальше последней точки пути.
@export var base_position: Vector2 = Vector2(1750, 540)

# Позиции свободных слотов под башни (стоят ВДОЛЬ пути, но не НА нём).
@export var tower_slot_positions: PackedVector2Array = PackedVector2Array()
