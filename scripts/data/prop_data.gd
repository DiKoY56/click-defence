class_name PropData
extends Resource
# Данные одного пропса парка. texture может быть null -> рисуется плейсхолдер-фигура.
# clearance_radius = половина ширины в МИРОВЫХ px (предвыровнена по спеке художника:
# арт 1x * scale 2 / 2). role — семантическая категория для гарантии расстановки
# (tree/lamp/bench/decor); id — уникальный ключ варианта (tree_oak, tree_birch...).

@export var id: StringName = &"prop"
@export var role: StringName = &"decor"
@export var texture: Texture2D = null
@export var scale: float = 2.0
@export var weight: float = 1.0
@export var clearance_radius: float = 40.0
@export var placeholder_color: Color = Color(0.4, 0.5, 0.35)
