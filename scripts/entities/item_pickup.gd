class_name ItemPickup
extends Node2D
## Non-Sinag pickups: health herb, Sinag magnet, big Sinag gem and the elite chest.
## Walk into it (or let it drift to you once inside pickup range) to collect.

signal collected(drop: int)

const COLLECT_DISTANCE := 18.0

var drop: int = RunDirector.Drop.HERB
var hero: Hero


func _physics_process(_delta: float) -> void:
	if hero == null or not is_instance_valid(hero) or hero.is_dead():
		return
	var reach: float = COLLECT_DISTANCE
	if drop == RunDirector.Drop.CHEST:
		reach += 8.0
	if global_position.distance_to(hero.global_position) <= reach:
		collected.emit(drop)
		queue_free()


func _draw() -> void:
	match drop:
		RunDirector.Drop.HERB:
			draw_circle(Vector2.ZERO, 8.0, Color(0.3, 0.85, 0.35))
			draw_rect(Rect2(-2.0, -6.0, 4.0, 12.0), Color(1, 1, 1))
			draw_rect(Rect2(-6.0, -2.0, 12.0, 4.0), Color(1, 1, 1))
		RunDirector.Drop.MAGNET:
			draw_arc(Vector2(0, 2), 8.0, PI, TAU, 16, Color(0.95, 0.3, 0.3), 4.0)
			draw_rect(Rect2(-10.0, 2.0, 5.0, 7.0), Color(0.9, 0.9, 0.95))
			draw_rect(Rect2(5.0, 2.0, 5.0, 7.0), Color(0.9, 0.9, 0.95))
		RunDirector.Drop.BIG_XP:
			var gem := PackedVector2Array([Vector2(0, -13), Vector2(10, 0), Vector2(0, 13), Vector2(-10, 0)])
			draw_colored_polygon(gem, Color(1.0, 0.85, 0.3))
			draw_polyline(PackedVector2Array([gem[0], gem[1], gem[2], gem[3], gem[0]]), Color(1, 1, 1), 2.0)
		RunDirector.Drop.CHEST:
			draw_rect(Rect2(-13.0, -9.0, 26.0, 18.0), Color(0.75, 0.55, 0.2))
			draw_rect(Rect2(-13.0, -9.0, 26.0, 18.0), Color(0.3, 0.2, 0.05), false, 2.0)
			draw_rect(Rect2(-3.0, -3.0, 6.0, 7.0), Color(1.0, 0.9, 0.4))
