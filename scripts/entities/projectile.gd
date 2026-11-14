class_name Projectile
extends Node2D
## A straight-flying shot. Assumes its parent sits at the world origin.
## Finds targets through the enemy manager's spatial grid, not by scanning every enemy.

var damage: float = 1.0
var hit_radius: float = 8.0
var pierce: int = 0
var color: Color = Color(0.65, 0.95, 1.0)

var _enemies: EnemyManager
var _velocity: Vector2 = Vector2.ZERO
var _life_left: float = 1.0
var _already_hit: Dictionary = {}  # enemy serial -> true
var _found: Array = []


func setup(enemies: EnemyManager, start: Vector2, direction: Vector2, speed: float, hit_damage: float, lifetime: float, radius: float, pierce_count: int) -> void:
	_enemies = enemies
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
	if _enemies == null:
		return
	_enemies.grid.query_circle(position, hit_radius + EnemyData.MAX_RADIUS, _found)
	for item in _found:
		var enemy: Enemy = item
		if not enemy.is_targetable() or _already_hit.has(enemy.serial):
			continue
		if position.distance_to(enemy.position) <= hit_radius + enemy.data.radius:
			enemy.take_damage(damage)
			_already_hit[enemy.serial] = true
			pierce -= 1
			if pierce < 0:
				queue_free()
				return


func _draw() -> void:
	draw_circle(Vector2.ZERO, hit_radius, color)
