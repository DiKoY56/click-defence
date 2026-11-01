class_name Ground
extends Node2D
# Слой земли. Базовый цвет парка + опциональный тайлинг, если художник положит
# assets/art/ground_tile.png (мостим циклом в _draw, флаг repeat на импорте не нужен).

const BASE_COLOR := Color(0.20, 0.24, 0.17)
const TILE_PATH := "res://assets/art/ground_tile.png"
const TILE_SCALE := 2.0

var tile: Texture2D = null

func _ready() -> void:
	if ResourceLoader.exists(TILE_PATH):
		tile = load(TILE_PATH) as Texture2D

func _draw() -> void:
	var arena: Vector2 = MapValidator.ARENA_SIZE
	draw_rect(Rect2(Vector2.ZERO, arena), BASE_COLOR)
	if tile == null:
		return
	var ts: Vector2 = tile.get_size() * TILE_SCALE
	var cols := ceili(arena.x / ts.x)
	var rows := ceili(arena.y / ts.y)
	for cy in rows:
		for cx in cols:
			draw_texture_rect(tile, Rect2(Vector2(cx * ts.x, cy * ts.y), ts), false)
