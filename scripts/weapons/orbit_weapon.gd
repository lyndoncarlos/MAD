class_name OrbitWeapon
extends WeaponBase
## Orbs circle the hero and damage enemies they touch. `cooldown` in the data is the
## delay between hits on the same enemy, so crowds can't be melted every frame.

const PRUNE_INTERVAL := 5.0

var _angle: float = 0.0
var _clock: float = 0.0
var _next_prune: float = PRUNE_INTERVAL
var _last_hit: Dictionary = {}  # enemy instance id -> clock time of last hit
var _orb_positions: Array[Vector2] = []


func _physics_process(delta: float) -> void:
	if data == null or hero == null:
		return
	_clock += delta
	_angle += deg_to_rad(data.orbit_speed_deg) * delta

	var count: int = current_projectile_count()
	var radius: float = data.orbit_radius * data.area
	_orb_positions.clear()
	for i in count:
		var orb_angle: float = _angle + TAU * float(i) / float(count)
		_orb_positions.append(Vector2.RIGHT.rotated(orb_angle) * radius)

	var damage: float = current_damage()
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		if enemy == null or not enemy.is_targetable():
			continue
		var enemy_id: int = enemy.get_instance_id()
		if _clock - _last_hit.get(enemy_id, -999.0) < data.cooldown:
			continue
		for local_pos in _orb_positions:
			var distance: float = to_global(local_pos).distance_to(enemy.global_position)
			if distance <= data.hit_radius + enemy.data.radius:
				enemy.take_damage(damage)
				_last_hit[enemy_id] = _clock
				break

	if _clock >= _next_prune:
		_prune_hits()
		_next_prune = _clock + PRUNE_INTERVAL
	queue_redraw()


func _prune_hits() -> void:
	for enemy_id in _last_hit.keys():
		if _clock - _last_hit[enemy_id] > PRUNE_INTERVAL:
			_last_hit.erase(enemy_id)


func _draw() -> void:
	if data == null:
		return
	for local_pos in _orb_positions:
		draw_circle(local_pos, data.hit_radius, Color(0.95, 0.95, 1.0))
