extends RefCounted
## XP curve and levelling rules.


func run() -> Array:
	var failures: Array = []
	var curve := LevelCurveData.new()  # defaults: base 5, linear 3, quad 0.2

	# Known values: L1 = 5, L2 = round(5+3+0.2) = 8, L3 = round(5+6+0.8) = 12.
	if not is_equal_approx(curve.xp_to_next(1), 5.0):
		failures.append("xp_to_next(1) should be 5, got %s" % curve.xp_to_next(1))
	if not is_equal_approx(curve.xp_to_next(2), 8.0):
		failures.append("xp_to_next(2) should be 8, got %s" % curve.xp_to_next(2))
	if not is_equal_approx(curve.xp_to_next(3), 12.0):
		failures.append("xp_to_next(3) should be 12, got %s" % curve.xp_to_next(3))

	# The curve must never get cheaper as you level.
	var previous := 0.0
	for lvl in range(1, 60):
		var needed: float = curve.xp_to_next(lvl)
		if needed < previous:
			failures.append("xp curve decreased at level %d" % lvl)
			break
		if needed < 1.0:
			failures.append("xp curve below 1 at level %d" % lvl)
			break
		previous = needed

	# Exactly enough XP levels up once and leaves nothing over.
	var state := RunState.new(curve)
	if state.add_xp(5.0) != 1 or state.level != 2 or not is_equal_approx(state.xp, 0.0):
		failures.append("5 xp should give level 2 with 0 left (level=%d xp=%s)" % [state.level, state.xp])
	if state.pending_level_ups != 1:
		failures.append("pending_level_ups should be 1, got %d" % state.pending_level_ups)

	# A big pickup can grant several levels at once: 8 (L2) + 12 (L3) = 20, leaving 3.
	var big := RunState.new(curve)
	big.add_xp(5.0)   # to level 2
	var gained: int = big.add_xp(23.0)
	if gained != 2 or big.level != 4:
		failures.append("23 xp at level 2 should give +2 levels (got +%d, level %d)" % [gained, big.level])
	if not is_equal_approx(big.xp, 3.0):
		failures.append("leftover xp should be 3, got %s" % big.xp)

	# Passive multipliers stack by level and only affect their own stat.
	var agimat := UpgradeData.new()
	agimat.id = &"passive_agimat"
	agimat.stat = &"damage_mult"
	agimat.value_per_level = 0.1
	var stats := RunState.new(curve)
	if not is_equal_approx(stats.stat_mult(&"damage_mult"), 1.0):
		failures.append("stat_mult with no passives should be 1.0")
	stats.set_passive(agimat, 3)
	if not is_equal_approx(stats.stat_mult(&"damage_mult"), 1.3):
		failures.append("agimat level 3 should give 1.3x damage, got %s" % stats.stat_mult(&"damage_mult"))
	if not is_equal_approx(stats.stat_mult(&"move_speed_mult"), 1.0):
		failures.append("damage passive must not change move speed")

	return failures
