extends RefCounted
## Guards the shipped spawn curves against authoring mistakes: gaps, jumps and cap blow-ups.

## The M1 prototype scans enemy groups linearly, so keep the worst case modest.
## Raise this in M2 once pooling and spatial lookup exist.
const M1_MAX_ALIVE := 300


func run() -> Array:
	var failures: Array = []
	var result: Dictionary = DataLoader.load_all()
	for entry in result["entries"]:
		if entry["category"] != &"spawn_curves":
			continue
		_check_curve(entry["resource"] as SpawnCurveData, str(entry["path"]), failures)
	return failures


func _check_curve(curve: SpawnCurveData, path: String, failures: Array) -> void:
	var by_enemy: Dictionary = {}
	for wave in curve.waves:
		if not by_enemy.has(wave.enemy_id):
			by_enemy[wave.enemy_id] = []
		(by_enemy[wave.enemy_id] as Array).append(wave)

	for enemy_id in by_enemy:
		var waves: Array = by_enemy[enemy_id]
		waves.sort_custom(func(a: SpawnWave, b: SpawnWave) -> bool: return a.start_minute < b.start_minute)

		if not is_zero_approx(waves[0].start_minute):
			failures.append("%s: '%s' waves should start at minute 0" % [path, enemy_id])
		if absf(waves[waves.size() - 1].end_minute - curve.duration_minutes) > 0.001:
			failures.append("%s: '%s' waves should end at the curve duration (%s)" % [path, enemy_id, curve.duration_minutes])

		for i in waves.size():
			var wave: SpawnWave = waves[i]
			if wave.rate_at(1.0) < wave.rate_at(0.0) - 0.0001:
				failures.append("%s: '%s' wave %d rate falls during the wave" % [path, enemy_id, i])
			if wave.cap_at(1.0) < wave.cap_at(0.0):
				failures.append("%s: '%s' wave %d cap falls during the wave" % [path, enemy_id, i])
			if wave.cap_at(1.0) * curve.max_pressure > M1_MAX_ALIVE:
				failures.append("%s: '%s' wave %d could exceed %d alive at max pressure" % [path, enemy_id, i, M1_MAX_ALIVE])
			if i == 0:
				continue
			var previous: SpawnWave = waves[i - 1]
			if absf(previous.end_minute - wave.start_minute) > 0.001:
				failures.append("%s: '%s' gap or overlap between waves %d and %d" % [path, enemy_id, i - 1, i])
			if absf(previous.rate_at(1.0) - wave.rate_at(0.0)) > 0.001:
				failures.append("%s: '%s' spawn rate jumps between waves %d and %d" % [path, enemy_id, i - 1, i])
			if previous.cap_at(1.0) != wave.cap_at(0.0):
				failures.append("%s: '%s' alive cap jumps between waves %d and %d" % [path, enemy_id, i - 1, i])
			var pack_step: int = wave.pack_at(0.0) - previous.pack_at(1.0)
			if pack_step < 0 or pack_step > 1:
				failures.append("%s: '%s' pack size jumps by %d between waves %d and %d" % [path, enemy_id, pack_step, i - 1, i])
