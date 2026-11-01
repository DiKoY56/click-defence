class_name PathOverlay
extends Node2D
# Отладочная визуализация пути: baked-кривая + контрольные точки + длина.
# Не имеет коллайдов — не влияет на геймплей, только для тестовых сцен Фазы B/C.

var baked: PackedVector2Array = PackedVector2Array()
var control: PackedVector2Array = PackedVector2Array()
var label_text: String = ""

func set_data(_baked: PackedVector2Array, _control: PackedVector2Array, _label: String) -> void:
	baked = _baked
	control = _control
	label_text = _label
	queue_redraw()

func _draw() -> void:
	if baked.size() >= 2:
		draw_polyline(baked, Color(0.3, 0.7, 1.0, 0.85), 4.0)
	for i in control.size():
		var col := Color(1.0, 0.4, 0.4) if i == 0 else (Color(0.4, 1.0, 0.4) if i == control.size() - 1 else Color(1.0, 0.85, 0.4))
		draw_circle(control[i], 9.0, col)
	# подпись рисуем в фиксированном углу арены, а НЕ у control[0]:
	# первая контрольная точка — спавн за левым краем (x<0), туда текст и уезжал.
	if label_text != "":
		draw_string(ThemeDB.fallback_font, Vector2(20, 40), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
