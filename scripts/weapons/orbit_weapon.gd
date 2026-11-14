class_name OrbitWeapon
extends WeaponBase
## Orbs circle the hero and damage enemies they touch. `cooldown` in the data is the
## delay between hits on the same enemy, so crowds can't be melted every frame.

const PRUNE_INTERVAL := 5.0

var _angle: float = 0.0
var _clock: float = 0.0
var _next_prune: float = PRUNE_INTERVAL
var _last_hit: Dictionary = {}  # enemy serial -> clock time of last hit
var _orb_positions: Array[Vector2] = []
var _found: Array = []


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

	if hero.enemies != null:
		var damage: float = current_damage()
		for local_pos in _orb_positions:
			var orb_pos: Vector2 = hero.position + local_pos
			hero.enemies.grid.query_circle(orb_pos, data.hit_radius + EnemyData.MAX_RADIUS, _found)
			for item in _found:
				var enemy: Enemy = item
				if not enemy.is_targetable():
					continue
				if orb_pos.distance_to(enemy.position) > data.hit_radius + enemy.data.radius:
					continue
				var last_hit: float = _last_hit.get(enemy.serial, -999.0)
				if _clock - last_hit < data.cooldown:
					continue
				enemy.take_damage(damage)
				_last_hit[enemy.serial] = _clock

	if _clock >= _next_prune:
		_prune_hits()
		_next_prune = _clock + PRUNE_INTERVAL
	queue_redraw()


func _prune_hits() -> void:
	for enemy_serial in _last_hit.keys():
		if _clock - _last_hit[enemy_serial] > PRUNE_INTERVAL:
			_last_hit.erase(enemy_serial)


func _draw() -> void:
	if data == null:
		return
	for local_pos in _orb_positions:
		draw_circle(local_pos, data.hit_radius, Color(0.95, 0.95, 1.0))
