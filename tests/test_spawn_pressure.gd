extends RefCounted
## Pressure rises with level and build strength, is clamped, and never misbehaves.


func run() -> Array:
	var failures: Array = []
	var curve := SpawnCurveData.new()  # defaults: +2%/level, power 0.15, clamp 1.0 to 2.0

	var at_start: float = SpawnPressure.compute(1, 10.0, 10.0, curve)
	if not is_equal_approx(at_start, 1.0):
		failures.append("level 1 with baseline dps should be 1.0, got %s" % at_start)

	var level_11: float = SpawnPressure.compute(11, 10.0, 10.0, curve)
	if not is_equal_approx(level_11, 1.2):
		failures.append("level 11 should add 20%% (1.2), got %s" % level_11)

	# 4x damage output: sqrt(4) = 2, so +0.15 * (2 - 1) = 1.15.
	var strong: float = SpawnPressure.compute(1, 40.0, 10.0, curve)
	if not is_equal_approx(strong, 1.15):
		failures.append("4x dps at level 1 should be 1.15, got %s" % strong)

	if not is_equal_approx(SpawnPressure.compute(100, 10.0, 10.0, curve), 2.0):
		failures.append("pressure should clamp at max_pressure (2.0)")

	# A weaker-than-baseline build is floored at min_pressure.
	if not is_equal_approx(SpawnPressure.compute(1, 1.0, 10.0, curve), 1.0):
		failures.append("a weak build should not drop pressure below min_pressure")

	# Bad inputs must not produce NaN or values outside the clamp.
	var odd: float = SpawnPressure.compute(0, -5.0, 0.0, curve)
	if is_nan(odd) or odd < curve.min_pressure or odd > curve.max_pressure:
		failures.append("zero baseline / negative dps gave a bad value: %s" % odd)

	# More level never lowers pressure.
	var previous := 0.0
	for lvl in range(1, 80):
		var p: float = SpawnPressure.compute(lvl, 30.0, 10.0, curve)
		if p < previous - 0.00001:
			failures.append("pressure dropped when level rose to %d" % lvl)
			break
		previous = p

	# Turning the power bonus off makes pressure depend on level only.
	var level_only := SpawnCurveData.new()
	level_only.power_bonus = 0.0
	if not is_equal_approx(SpawnPressure.compute(1, 1000.0, 10.0, level_only), 1.0):
		failures.append("power_bonus 0 should ignore dps")

	return failures
