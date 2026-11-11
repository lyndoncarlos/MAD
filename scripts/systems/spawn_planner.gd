class_name SpawnPlanner
extends RefCounted
## Decides WHAT to spawn each physics tick from a SpawnCurveData. No nodes, so it
## can be unit tested: given time and how many enemies are alive, it returns ids.

var curve: SpawnCurveData
var _accumulators: Array[float] = []


func _init(spawn_curve: SpawnCurveData) -> void:
	curve = spawn_curve
	_accumulators.resize(curve.waves.size())
	_accumulators.fill(0.0)


## alive_counts maps enemy id -> number currently alive. Returns enemy ids to spawn now.
func plan(delta: float, run_time_seconds: float, alive_counts: Dictionary) -> Array[StringName]:
	var minute: float = run_time_seconds / 60.0
	var result: Array[StringName] = []
	var counts: Dictionary = alive_counts.duplicate()
	for i in curve.waves.size():
		var wave: SpawnWave = curve.waves[i]
		if wave == null or minute < wave.start_minute or minute >= wave.end_minute:
			_accumulators[i] = 0.0
			continue
		_accumulators[i] += wave.spawns_per_second * delta
		while _accumulators[i] >= 1.0:
			_accumulators[i] -= 1.0
			var alive: int = counts.get(wave.enemy_id, 0)
			if alive >= wave.max_alive:
				continue  # at the cap: drop this spawn rather than burst later
			counts[wave.enemy_id] = alive + 1
			result.append(wave.enemy_id)
	return result


## A point on a circle around the player, for off-screen spawning.
static func ring_offset(angle: float, radius: float) -> Vector2:
	return Vector2.RIGHT.rotated(angle) * radius
