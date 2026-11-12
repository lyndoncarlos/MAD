extends RefCounted
## The emerge burst must start fast, end at normal speed, and never speed up again.


func run() -> Array:
	var failures: Array = []
	var base := 70.0
	var mult := 3.5
	var seconds := 0.7

	if not is_equal_approx(EnemyMotion.burst_speed(0.0, base, mult, seconds), base * mult):
		failures.append("burst should start at base * mult (245), got %s" % EnemyMotion.burst_speed(0.0, base, mult, seconds))
	if not is_equal_approx(EnemyMotion.burst_speed(seconds, base, mult, seconds), base):
		failures.append("burst should end at base speed, got %s" % EnemyMotion.burst_speed(seconds, base, mult, seconds))
	if not is_equal_approx(EnemyMotion.burst_speed(5.0, base, mult, seconds), base):
		failures.append("after the burst the speed must stay at base")

	# Never speeds up during the burst, never drops below base.
	var previous := INF
	for i in 71:
		var sample_time: float = float(i) * 0.01
		var speed: float = EnemyMotion.burst_speed(sample_time, base, mult, seconds)
		if speed > previous + 0.0001:
			failures.append("burst speed increased at t=%s" % sample_time)
			break
		if speed < base - 0.0001:
			failures.append("burst speed fell below base at t=%s" % sample_time)
			break
		previous = speed

	# Distance covered by the burst (numeric integral) is between base and peak speed times duration.
	var distance := 0.0
	var step := 0.001
	var t := 0.0
	while t < seconds:
		distance += EnemyMotion.burst_speed(t, base, mult, seconds) * step
		t += step
	# Exact value: base * seconds * (1 + (mult - 1) * 2/3) = 70 * 0.7 * 2.6667 = 130.67
	if absf(distance - 130.67) > 1.5:
		failures.append("burst distance should be about 130.7 px, got %s" % distance)

	# Burst switched off: always the base speed.
	if not is_equal_approx(EnemyMotion.burst_speed(0.0, base, 1.0, seconds), base):
		failures.append("mult 1.0 should disable the burst")
	if not is_equal_approx(EnemyMotion.burst_speed(0.0, base, mult, 0.0), base):
		failures.append("zero duration should disable the burst")

	return failures
