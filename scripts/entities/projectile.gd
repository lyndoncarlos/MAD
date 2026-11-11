class_name Projectile
extends Node2D
## A straight-flying shot. Assumes its parent sits at the world origin.

var damage: float = 1.0
var hit_radius: float = 8.0
var pierce: int = 0
var color: Color = Color(0.65, 0.95, 1.0)

var _velocity: Vector2 = Vector2.ZERO
var _life_left: float = 1.0
var _already_hit: Dictionary = {}


func setup(start: Vector2, direction: Vector2, speed: float, hit_damage: float, lifetime: float, radius: float, pierce_count: int) -> void:
	position = start
	_velocity = direction.normalized() * speed
	damage = hit_damage
	_life_left = lifetime
	hit_radius = radius
	pierce = pierce_count


func _physics_process(delta: float) -> void:
	position += _velocity * delta
	_life_left -= delta
	if _life_left <= 0.0:
		queue_free()
		return
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		if enemy == null or enemy.is_dying:
			continue
		var enemy_id: int = enemy.get_instance_id()
		if _already_hit.has(enemy_id):
			continue
		if global_position.distance_to(enemy.global_position) <= hit_radius + enemy.data.radius:
			enemy.take_damage(damage)
			_already_hit[enemy_id] = true
			pierce -= 1
			if pierce < 0:
				queue_free()
				return


func _draw() -> void:
	draw_circle(Vector2.ZERO, hit_radius, color)
