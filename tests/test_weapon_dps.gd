extends RefCounted
## DPS estimates must reflect upgrades that make you kill faster, and ignore the rest.


func _staff() -> WeaponData:
	var w := WeaponData.new()
	w.id = &"spirit_staff"
	w.pattern = WeaponData.Pattern.PROJECTILE
	w.base_damage = 10.0
	w.cooldown = 0.9
	w.projectile_count = 1
	w.extra_projectile_every_levels = 3
	w.damage_per_level = 0.15
	return w


func _asin() -> WeaponData:
	var w := WeaponData.new()
	w.id = &"asin"
	w.pattern = WeaponData.Pattern.ORBIT
	w.base_damage = 6.0
	w.cooldown = 0.6
	w.projectile_count = 2
	w.extra_projectile_every_levels = 3
	w.damage_per_level = 0.15
	return w


func run() -> Array:
	var failures: Array = []
	var staff: WeaponData = _staff()

	# Level 1: 10 damage every 0.9 s.
	if absf(WeaponMath.estimated_dps(staff, 1) - 10.0 / 0.9) > 0.01:
		failures.append("staff L1 dps should be 11.11, got %s" % WeaponMath.estimated_dps(staff, 1))
	# Level 4: damage 14.5 and 2 projectiles.
	if absf(WeaponMath.estimated_dps(staff, 4) - 14.5 * 2.0 / 0.9) > 0.01:
		failures.append("staff L4 dps should be 32.22, got %s" % WeaponMath.estimated_dps(staff, 4))
	# Orbit: 2 orbs, ~57.75% uptime, 6 damage / 0.6 s = 10 per second -> 5.775.
	if absf(WeaponMath.estimated_dps(_asin(), 1) - 5.775) > 0.01:
		failures.append("asin L1 dps should be about 5.78, got %s" % WeaponMath.estimated_dps(_asin(), 1))

	# RunState totals owned weapons, scaled by damage passives.
	var curve := LevelCurveData.new()
	var state := RunState.new(curve)
	if not is_equal_approx(state.estimated_dps(), 0.0):
		failures.append("an empty loadout should have 0 dps")
	state.set_weapon(staff, 1)
	if absf(state.estimated_dps() - 10.0 / 0.9) > 0.01:
		failures.append("loadout with the staff should be 11.11 dps")

	var agimat := UpgradeData.new()
	agimat.id = &"passive_agimat"
	agimat.stat = &"damage_mult"
	agimat.value_per_level = 0.1
	state.set_passive(agimat, 2)  # 1.2x damage
	if absf(state.estimated_dps() - 10.0 / 0.9 * 1.2) > 0.01:
		failures.append("agimat 2 should raise dps by 20%%, got %s" % state.estimated_dps())

	# Movement and pickup passives must not change dps.
	var bakya := UpgradeData.new()
	bakya.id = &"passive_bakya"
	bakya.stat = &"move_speed_mult"
	bakya.value_per_level = 0.08
	var before: float = state.estimated_dps()
	state.set_passive(bakya, 5)
	if not is_equal_approx(state.estimated_dps(), before):
		failures.append("a movement passive changed the dps estimate")

	# A second weapon adds to the total.
	state.set_weapon(_asin(), 1)
	if state.estimated_dps() <= before:
		failures.append("adding a weapon should raise dps")

	# Weapons added without data (set_weapon_level) are skipped, not crashed on.
	var legacy := RunState.new(curve)
	legacy.set_weapon_level(&"mystery", 5)
	if not is_equal_approx(legacy.estimated_dps(), 0.0):
		failures.append("a weapon without data should count as 0 dps")

	return failures
