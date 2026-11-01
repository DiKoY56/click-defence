class_name PropData
extends Resource
# Данные одного пропса парка. texture может быть null -> рисуется плейсхолдер-фигура.
# clearance_radius = половина ШИРИНЫ тела в МИРОВЫХ px (для зазоров по X и от дороги).
# body_height = ВЫСОТА тела от ножки до верха в МИРОВЫХ px (для удержания в арене по Y).
# Оба предвыровнены по спеке художника (арт 1x * scale 2). role — семантическая
# категория для зонирования расстановки (tree/lamp/bench/decor); id — ключ варианта.

@export var id: StringName = &"prop"
@export var role: StringName = &"decor"
@export var texture: Texture2D = null
@export var scale: float = 2.0
@export var weight: float = 1.0
@export var clearance_radius: float = 40.0
@export var body_height: float = 80.0
@export var placeholder_color: Color = Color(0.4, 0.5, 0.35)
