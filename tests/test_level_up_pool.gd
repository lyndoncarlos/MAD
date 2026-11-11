extends RefCounted
## Level-up options: valid, unique, capped, reproducible from a seed.


func _weapon(id: String, max_level: int = 8) -> WeaponData:
	var w := WeaponData.new()
	w.id = StringName(id)
	w.display_name = id
	w.max_level = max_level
	return w


func _passive(id: String, max_level: int = 5) -> UpgradeData:
	var p := UpgradeData.new()
	p.id = StringName(id)
	p.display_name = id
	p.stat = &"damage_mult"
	p.max_level = max_level
	return p


func _ids(options: Array) -> Array:
	var ids: Array = []
	for option in options:
		ids.append("%s:%s" % [option["kind"], option["id"]])
	return ids


func run() -> Array:
	var failures: Array = []
	var curve := LevelCurveData.new()
	var weapons: Array = [_weapon("a"), _weapon("b"), _weapon("c")]
	var passives: Array = [_passive("p"), _passive("q")]

	# 1. Three unique options, none maxed out.
	var state := RunState.new(curve)
	state.set_weapon_level(&"a", 8)  # maxed: must never be offered
	var rng := RunRng.new()
	rng.start(7)
	var options: Array = LevelUpPool.build_options(state, weapons, passives, rng, 3)
	if options.size() != 3:
		failures.append("expected 3 options, got %d" % options.size())
	var seen: Dictionary = {}
	for key in _ids(options):
		if seen.has(key):
			failures.append("duplicate option %s" % key)
		seen[key] = true
		if key == "weapon:a":
			failures.append("a maxed weapon was offered")

	# 2. Same seed gives the same options; the result does not depend on other streams.
	var rng_a := RunRng.new()
	var rng_b := RunRng.new()
	rng_a.start(2024)
	rng_b.start(2024)
	for i in 50:
		rng_b.next_float(RunRng.SPAWN)  # unrelated stream, must not matter
	var first: Array = _ids(LevelUpPool.build_options(RunState.new(curve), weapons, passives, rng_a, 3))
	var second: Array = _ids(LevelUpPool.build_options(RunState.new(curve), weapons, passives, rng_b, 3))
	if first != second:
		failures.append("same seed produced different level-up options: %s vs %s" % [first, second])

	# 3. With every weapon slot full, a 7th weapon is never offered as new.
	var many: Array = []
	for i in range(1, 8):
		many.append(_weapon("w%d" % i))
	var full := RunState.new(curve)
	for i in range(1, 7):
		full.set_weapon_level(StringName("w%d" % i), 1)
	for trial in 30:
		var trial_rng := RunRng.new()
		trial_rng.start(trial)
		for key in _ids(LevelUpPool.build_options(full, many, [], trial_rng, 3)):
			if key == "weapon:w7":
				failures.append("offered a 7th weapon with all slots full (seed %d)" % trial)

	# 4. Nothing left to offer: fall back to the heal option.
	var maxed := RunState.new(curve)
	maxed.set_weapon_level(&"a", 8)
	var only_weapon: Array = [_weapon("a")]
	var fallback: Array = LevelUpPool.build_options(maxed, only_weapon, [], rng, 3)
	if fallback.size() != 1 or fallback[0]["kind"] != "heal":
		failures.append("expected a single heal option when nothing else is available")

	# 5. Level-up options show the level the item will have after choosing.
	var owned := RunState.new(curve)
	owned.set_weapon_level(&"a", 2)
	var up: Array = LevelUpPool.build_options(owned, [_weapon("a")], [], rng, 3)
	if up.size() != 1 or up[0]["level"] != 3:
		failures.append("an owned level 2 weapon should be offered as level 3")

	return failures
