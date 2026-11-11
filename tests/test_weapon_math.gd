extends RefCounted
## Damage and projectile-count scaling, checked without a running scene.


func run() -> Array:
	var failures: Array = []

	var data := WeaponData.new()
	data.id = &"test_weapon"
	data.base_damage = 10.0
	data.damage_per_level = 0.15
	data.projectile_count = 1
	data.extra_projectile_every_levels = 3

	var curve := LevelCurveData.new()
	var state := RunState.new(curve)
	var weapon := ProjectileWeapon.new()
	weapon.data = data
	weapon.run_state = state

	weapon.level = 1
	if not is_equal_approx(weapon.current_damage(), 10.0):
		failures.append("level 1 damage should be 10, got %s" % weapon.current_damage())
	weapon.level = 3
	if not is_equal_approx(weapon.current_damage(), 13.0):  # 10 * (1 + 0.15*2)
		failures.append("level 3 damage should be 13, got %s" % weapon.current_damage())

	# A damage passive at level 2 (+10% each) multiplies on top: 13 * 1.2 = 15.6.
	var agimat := UpgradeData.new()
	agimat.id = &"passive_agimat"
	agimat.stat = &"damage_mult"
	agimat.value_per_level = 0.1
	state.set_passive(agimat, 2)
	if not is_equal_approx(weapon.current_damage(), 15.6):
		failures.append("level 3 + agimat 2 should be 15.6, got %s" % weapon.current_damage())

	# +1 projectile every 3 levels: L1-3 = 1, L4-6 = 2, L7-8 = 3.
	var expected := {1: 1, 3: 1, 4: 2, 6: 2, 7: 3, 8: 3}
	for lvl in expected:
		weapon.level = lvl
		if weapon.current_projectile_count() != expected[lvl]:
			failures.append("level %d should fire %d projectiles, got %d" % [lvl, expected[lvl], weapon.current_projectile_count()])

	# With the bonus turned off, the count never grows.
	data.extra_projectile_every_levels = 0
	weapon.level = 8
	if weapon.current_projectile_count() != 1:
		failures.append("count should stay 1 when extra_projectile_every_levels is 0")

	weapon.free()
	return failures
