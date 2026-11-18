class_name Trail
extends Node2D
# Слой тропы: рисуется по той же baked-кривой, что читает враг (единый источник
# геометрии), поэтому тропа физически совпадает с линией ходьбы.
# z_index = -15: между землёй (-20) и пропсами (-10) — трава под тропой,
# фонари/деревья поверх её краёв. Коллайдов нет: на геймплей не влияет.
# Рисуем цепочкой кругов по baked-точкам (шаг 20px << радиуса): непрерывная
# полоса со скруглёнными углами без артефактов стыков толстой polyline.
# TODO(арт): когда появится тайл дорожки — замощение добавляется ТОЛЬКО здесь.

const BORDER_RADIUS := 48.0   # полуширина окантовки (~96px полосы)
const FILL_RADIUS := 42.0     # полуширина заливки (~84px, шире корпуса бомжа)
const BORDER_COLOR := Color(0.28, 0.24, 0.17)
const FILL_COLOR := Color(0.45, 0.38, 0.27)

var baked: PackedVector2Array = PackedVector2Array()

func setup(path_points: PackedVector2Array) -> void:
	baked = MapValidator._bake_path(path_points)
	queue_redraw()

func _draw() -> void:
	# проход 1: тёмная окантовка
	for p in baked:
		draw_circle(p, BORDER_RADIUS, BORDER_COLOR)
	# проход 2: утоптанная земля поверх, оставляя бордюр 6px по краям
	for p in baked:
		draw_circle(p, FILL_RADIUS, FILL_COLOR)
