class_name Trail
extends Node2D
# Тропа по той же baked-кривой, что читает враг. z=-15 (между землёй и пропсами).
# Хвост обрезается по AABB ларька: точки, попавшие внутрь его прямоугольника,
# отбрасываются, поэтому тропа доходит до нижней кромки ларька и ныряет под него
# (ларёк рисуется поверх), а не упирается в его центр/окно.

const BORDER_RADIUS := 58.0
const FILL_RADIUS := 52.0
const BORDER_COLOR := Color(0.28, 0.24, 0.17)
const FILL_COLOR := Color(0.45, 0.38, 0.27)
const BASE_HALF := 128.0

var baked: PackedVector2Array = PackedVector2Array()

func setup(path_points: PackedVector2Array, base_pos: Vector2) -> void:
	var pts := MapValidator._bake_path(path_points)
	var base_rect := Rect2(base_pos.x - BASE_HALF, base_pos.y - BASE_HALF, BASE_HALF * 2.0, BASE_HALF * 2.0)
	var end := pts.size()
	while end > 2 and base_rect.has_point(pts[end - 1]):
		end -= 1
	baked = pts.slice(0, end)
	queue_redraw()

func _draw() -> void:
	for p in baked:
		draw_circle(p, BORDER_RADIUS, BORDER_COLOR)
	for p in baked:
		draw_circle(p, FILL_RADIUS, FILL_COLOR)
