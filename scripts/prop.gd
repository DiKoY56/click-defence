class_name Prop
extends Node2D
# Один пропс. Позиция узла = точка касания земли (низ-центр). Рисует текстуру
# (вниз якорем, масштаб data.scale) или, если текстуры нет, мягкий плейсхолдер-круг.
# Статичен: _draw вызывается один раз, коллайдов нет — на геймплей не влияет.

var data: PropData = null

func _draw() -> void:
	if data == null:
		return
	if data.texture != null:
		var s: Vector2 = data.texture.get_size() * data.scale
		draw_texture_rect(data.texture, Rect2(-s.x * 0.5, -s.y, s.x, s.y), false)
	else:
		# плейсхолдер: круг, касающийся якорной линии снизу (центр на -r по Y)
		draw_circle(Vector2(0.0, -data.clearance_radius), data.clearance_radius, data.placeholder_color)
