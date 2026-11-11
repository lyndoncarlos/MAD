extends RefCounted
## The spawn plan must follow the curve: right rate, respects caps, quiet outside windows.


func _curve(rate: float, start_minute: float, end_minute: float, cap: int) -> SpawnCurveData:
	var wave := SpawnWave.new()
	wave.start_minute = start_minute
	wave.end_minute = end_minute
	wave.enemy_id = &"tiyanak"
	wave.spawns_per_second = rate
	wave.max_alive = cap
	var curve := SpawnCurveData.new()
	curve.duration_minutes = 10.0
	curve.waves.append(wave)
	return curve


func run() -> Array:
	var failures: Array = []
	var step := 1.0 / 60.0

	# 1. Rate: 2 spawns/second for 60 seconds is about 120 spawns.
	var planner := SpawnPlanner.new(_curve(2.0, 0.0, 5.0, 100000))
	var total := 0
	for i in 3600:
		total += planner.plan(step, float(i) * step, {}).size()
	if absi(total - 120) > 1:
		failures.append("2/s for 60s should spawn about 120, got %d" % total)

	# 2. The alive cap is respected.
	var capped := SpawnPlanner.new(_curve(5.0, 0.0, 5.0, 5))
	var capped_total := 0
	for i in 600:
		capped_total += capped.plan(step, float(i) * step, {&"tiyanak": 5}).size()
	if capped_total != 0:
		failures.append("spawned %d enemies while at the alive cap" % capped_total)

	# 3. Nothing spawns outside the wave's window (waves run minutes 1 to 2).
	var windowed := SpawnPlanner.new(_curve(5.0, 1.0, 2.0, 1000))
	var before := 0
	for i in 600:
		before += windowed.plan(step, 10.0 + float(i) * step, {}).size()  # around 0:10
	if before != 0:
		failures.append("spawned %d enemies before the wave started" % before)
	var after := 0
	for i in 600:
		after += windowed.plan(step, 200.0 + float(i) * step, {}).size()  # around 3:20
	if after != 0:
		failures.append("spawned %d enemies after the wave ended" % after)

	# 4. Ring spawn points sit at the requested distance, at any angle.
	for angle in [0.0, 1.0, 2.5, 4.0, 6.0]:
		var length: float = SpawnPlanner.ring_offset(angle, 760.0).length()
		if absf(length - 760.0) > 0.01:
			failures.append("ring_offset length %s != 760 at angle %s" % [length, angle])

	return failures
