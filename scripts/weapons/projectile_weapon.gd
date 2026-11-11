class_name ProjectileWeapon
extends WeaponBase
## Fires a (possibly fanned) volley at the nearest enemy in range.

const SPREAD_RADIANS := 0.2

var _cooldown_left: float = 0.0


func _physics_process(delta: float) -> void:
	if data == null or hero == null:
		return
	_cooldown_left -= delta
	if _cooldown_left > 0.0:
		return
	var target := Targeting.nearest_enemy(get_tree(), hero.global_position, data.target_range)
	if target == null:
		return  # stay ready; fire as soon as something comes into range
	_fire_volley((target.global_position - hero.global_position).normalized())
	_cooldown_left = data.cooldown


func _fire_volley(direction: Vector2) -> void:
	var count: int = current_projectile_count()
	var damage: float = current_damage()
	for i in count:
		var offset: float = (float(i) - float(count - 1) / 2.0) * SPREAD_RADIANS
		var shot := Projectile.new()
		shot.setup(
			hero.global_position,
			direction.rotated(offset),
			data.projectile_speed,
			damage,
			data.duration,
			data.hit_radius,
			data.pierce
		)
		hero.get_parent().add_child(shot)
