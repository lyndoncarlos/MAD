class_name SpawnPlanner
extends RefCounted
## Decides WHAT to spawn each physics tick from a SpawnCurveData. No nodes, so it
## can be unit tested: given time, pressure and how many enemies are alive, it returns orders.

var curve: SpawnCurveData
var _accumulators: Array[float] = []


func _init(spawn_curve: SpawnCurveData) -> void:
	curve = spawn_curve
	_accumulators.resize(curve.waves.size())
	_accumulators.fill(0.0)


## alive_counts maps enemy id -> number currently alive. `pressure` scales every
## wave's spawn rate and alive cap (1.0 = as authored). Returns packs to spawn now.
func plan(delta: float, run_time_seconds: float, alive_counts: Dictionary, pressure: float = 1.0) -> Array[SpawnOrder]:
	var minute: float = run_time_seconds / 60.0
	var result: Array[SpawnOrder] = []
	var counts: Dictionary = alive_counts.duplicate()
	for i in curve.waves.size():
		var wave: SpawnWave = curve.waves[i]
		if wave == null or minute < wave.start_minute or minute >= wave.end_minute:
			_accumulators[i] = 0.0
			continue
		var progress: float = wave.progress_at(minute)
		var cap: int = roundi(float(wave.cap_at(progress)) * pressure)
		var pack: int = wave.pack_at(progress)
		_accumulators[i] += wave.rate_at(progress) * pressure * delta
		while _accumulators[i] >= 1.0:
			_accumulators[i] -= 1.0
			var alive: int = counts.get(wave.enemy_id, 0)
			var room: int = cap - alive
			if room <= 0:
				continue  # at the cap: drop this event rather than burst later
			var count: int = mini(pack, room)
			counts[wave.enemy_id] = alive + count
			result.append(SpawnOrder.new(wave.enemy_id, count))
	return result


## A point on a circle around the player, for off-screen spawning.
static func ring_offset(angle: float, radius: float) -> Vector2:
	return Vector2.RIGHT.rotated(angle) * radius
