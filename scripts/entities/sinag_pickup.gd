class_name SinagPickup
extends Node2D
## A shard of moonlight (XP). Drifts toward the hero once inside pickup range.

signal collected(amount: float)

const COLLECT_DISTANCE := 10.0
const ACCELERATION := 1400.0
const MAX_SPEED := 700.0

var value: float = 1.0
var hero: Hero

var _attracted: bool = false
var _speed: float = 0.0


func _ready() -> void:
	add_to_group(&"pickups")


func _physics_process(delta: float) -> void:
	if hero == null or not is_instance_valid(hero) or hero.is_dead():
		return
	var distance: float = global_position.distance_to(hero.global_position)
	if not _attracted and distance <= hero.pickup_radius():
		_attracted = true
	if not _attracted:
		return
	_speed = minf(_speed + ACCELERATION * delta, MAX_SPEED)
	global_position = global_position.move_toward(hero.global_position, _speed * delta)
	if global_position.distance_to(hero.global_position) <= COLLECT_DISTANCE:
		collected.emit(value)
		queue_free()


func _draw() -> void:
	var points := PackedVector2Array([Vector2(0, -6), Vector2(5, 0), Vector2(0, 6), Vector2(-5, 0)])
	draw_colored_polygon(points, Color(0.4, 0.95, 0.9))
