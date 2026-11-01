class_name SlotOverlay
extends Node2D
# Отладочная визуализация слотов: near (жёлтый) vs far (голубой) по расстоянию до пути.
# Класс ВЫВОДИТСЯ из геометрии (dist<=SLOT_NEAR_DIST -> near), не хранится в данных.

var slots: PackedVector2Array = PackedVector2Array()
var baked: PackedVector2Array = PackedVector2Array()
var counts: String = ""

func set_data(_slots: PackedVector2Array, _baked: PackedVector2Array, _counts: String) -> void:
	slots = _slots
	baked = _baked
	counts = _counts
	queue_redraw()

func _draw() -> void:
	for s in slots:
		var d := MapValidator._min_distance_to_polyline(s, baked)
		var col := Color(1.0, 0.85, 0.4) if d <= MapValidator.SLOT_NEAR_DIST else Color(0.4, 0.8, 1.0)
		draw_circle(s, 14.0, col)
		draw_arc(s, 14.0, 0.0, TAU, 24, Color(0, 0, 0, 0.6), 2.0)
	if counts != "":
		draw_string(ThemeDB.fallback_font, Vector2(20, 70), counts, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
