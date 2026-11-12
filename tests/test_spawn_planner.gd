extends RefCounted
## The spawn plan must follow the curve: rate, ramp, packs, caps, pressure and windows.

const STEP := 1.0 / 60.0


func _wave(start_minute: float, end_minute: float, rate: float, cap: int, pack: int = 1, end_rate: float = -1.0, end_cap: int = -1, end_pack: int = -1) -> SpawnWave:
	var wave := SpawnWave.new()
	wave.start_minute = start_minute
	wave.end_minute = end_minute
	wave.enemy_id = &"tiyanak"
	wave.spawns_per_second = rate
	wave.end_spawns_per_second = end_rate
	wave.max_alive = cap
	wave.end_max_alive = end_cap
	wave.pack_size = pack
	wave.end_pack_size = end_pack
	return wave


func _planner(wave: SpawnWave) -> SpawnPlanner:
	var curve := SpawnCurveData.new()
	curve.duration_minutes = 10.0
	curve.waves.append(wave)
	return SpawnPlanner.new(curve)


func _total(orders: Array) -> int:
	var total := 0
	for order in orders:
		total += order.count
	return total


func _simulate(planner: SpawnPlanner, from_seconds: float, seconds: float, pressure: float = 1.0) -> int:
	var total := 0
	var steps: int = int(seconds / STEP)
	for i in steps:
		total += _total(planner.plan(STEP, from_seconds + float(i) * STEP, {}, pressure))
	return total


func run() -> Array:
	var failures: Array = []

	# 1. Rate: 2 events/second for 60 seconds is about 120 spawns.
	var total: int = _simulate(_planner(_wave(0.0, 5.0, 2.0, 100000)), 0.0, 60.0)
	if absi(total - 120) > 2:
		failures.append("2/s for 60s should spawn about 120, got %d" % total)

	# 2. The alive cap is respected.
	var capped := _planner(_wave(0.0, 5.0, 5.0, 5))
	var capped_total := 0
	for i in 600:
		capped_total += _total(capped.plan(STEP, float(i) * STEP, {&"tiyanak": 5}))
	if capped_total != 0:
		failures.append("spawned %d enemies while at the alive cap" % capped_total)

	# 3. Nothing spawns outside the wave's window (minutes 1 to 2).
	var windowed := _planner(_wave(1.0, 2.0, 5.0, 1000))
	if _simulate(windowed, 10.0, 10.0) != 0:
		failures.append("spawned before the wave started")
	if _simulate(windowed, 200.0, 10.0) != 0:
		failures.append("spawned after the wave ended")

	# 4. Ring spawn points sit at the requested distance, at any angle.
	for angle in [0.0, 1.0, 2.5, 4.0, 6.0]:
		var length: float = SpawnPlanner.ring_offset(angle, 760.0).length()
		if absf(length - 760.0) > 0.01:
			failures.append("ring_offset length %s != 760 at angle %s" % [length, angle])

	# 5. A ramping wave (1 -> 3 events/s over 2 minutes) spawns far more at the end than at the start.
	var ramp := _planner(_wave(0.0, 2.0, 1.0, 100000, 1, 3.0))
	var early := 0
	var late := 0
	for i in int(120.0 / STEP):
		var now: float = float(i) * STEP
		var n: int = _total(ramp.plan(STEP, now, {}))
		if now < 10.0:
			early += n
		elif now >= 110.0:
			late += n
	if early < 8 or early > 14:
		failures.append("first 10s of a 1->3 ramp should spawn about 11, got %d" % early)
	if late < early * 2:
		failures.append("last 10s of the ramp (%d) should be more than double the first 10s (%d)" % [late, early])

	# 6. Pressure scales the rate: pressure 2.0 gives about double the spawns.
	var base_total: int = _simulate(_planner(_wave(0.0, 5.0, 1.0, 100000)), 0.0, 30.0, 1.0)
	var double_total: int = _simulate(_planner(_wave(0.0, 5.0, 1.0, 100000)), 0.0, 30.0, 2.0)
	if absi(double_total - base_total * 2) > 2:
		failures.append("pressure 2.0 should double spawns: %d vs %d" % [double_total, base_total])

	# 7. Pressure scales the alive cap too, and packs never exceed the room left.
	var cap_planner := _planner(_wave(0.0, 5.0, 5.0, 10, 3))  # cap 10, packs of 3
	var orders: Array = cap_planner.plan(1.0, 1.0, {&"tiyanak": 19}, 2.0)  # cap 20, 19 alive
	if _total(orders) != 1:
		failures.append("with cap 20 and 19 alive only 1 more may spawn, got %d" % _total(orders))
	var fresh := _planner(_wave(0.0, 5.0, 5.0, 10, 3))
	if _total(fresh.plan(1.0, 1.0, {}, 2.0)) != 20:
		failures.append("an empty field with cap 20 should fill to exactly 20")

	# 8. Packs: every order carries the pack size when there is room.
	var packs := _planner(_wave(0.0, 5.0, 1.0, 100000, 3))
	var pack_orders := 0
	for i in int(10.0 / STEP):
		for order in packs.plan(STEP, float(i) * STEP, {}):
			pack_orders += 1
			if order.count != 3:
				failures.append("pack should be 3, got %d" % order.count)
	if pack_orders < 9 or pack_orders > 11:
		failures.append("1 event/s for 10s should make about 10 packs, got %d" % pack_orders)

	# 9. Interpolation helpers.
	var ramp_wave: SpawnWave = _wave(0.0, 4.0, 1.0, 10, 1, 3.0, 30, 4)
	if not is_equal_approx(ramp_wave.rate_at(0.0), 1.0) or not is_equal_approx(ramp_wave.rate_at(1.0), 3.0):
		failures.append("rate_at should run 1.0 -> 3.0")
	if ramp_wave.cap_at(0.0) != 10 or ramp_wave.cap_at(1.0) != 30:
		failures.append("cap_at should run 10 -> 30")
	if ramp_wave.pack_at(0.0) != 1 or ramp_wave.pack_at(1.0) != 4:
		failures.append("pack_at should run 1 -> 4")
	var flat_wave: SpawnWave = _wave(0.0, 4.0, 2.0, 20)
	if not is_equal_approx(flat_wave.rate_at(1.0), 2.0) or flat_wave.cap_at(1.0) != 20 or flat_wave.pack_at(1.0) != 1:
		failures.append("an end value of -1 should mean 'same as start'")

	return failures
