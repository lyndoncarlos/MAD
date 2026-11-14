class_name BenchmarkStats
extends RefCounted
## Turns raw frame-time samples into the numbers that matter. Pure, so it is unit tested.

## Pass thresholds for the M2 gate (at 800 enemies).
const PASS_MIN_AVG_FPS := 55.0
const PASS_MAX_P99_MS := 25.0


## All inputs are milliseconds, one sample per frame.
static func summarize(frame_ms: PackedFloat32Array, process_ms: PackedFloat32Array, physics_ms: PackedFloat32Array) -> Dictionary:
	var sorted: Array = Array(frame_ms)
	sorted.sort()
	var avg_ms: float = _mean(frame_ms)
	return {
		"frames": frame_ms.size(),
		"avg_fps": snappedf(1000.0 / avg_ms, 0.1) if avg_ms > 0.0 else 0.0,
		"avg_frame_ms": snappedf(avg_ms, 0.01),
		"p95_frame_ms": snappedf(percentile(sorted, 0.95), 0.01),
		"p99_frame_ms": snappedf(percentile(sorted, 0.99), 0.01),
		"max_frame_ms": snappedf(sorted[sorted.size() - 1], 0.01) if not sorted.is_empty() else 0.0,
		"avg_process_ms": snappedf(_mean(process_ms), 0.01),
		"avg_physics_ms": snappedf(_mean(physics_ms), 0.01),
	}


## `sorted` must be ascending. q is 0.0 to 1.0. Nearest-rank method.
static func percentile(sorted: Array, q: float) -> float:
	if sorted.is_empty():
		return 0.0
	var rank: int = clampi(ceili(q * float(sorted.size())) - 1, 0, sorted.size() - 1)
	return sorted[rank]


static func verdict(result: Dictionary) -> String:
	if float(result["avg_fps"]) >= PASS_MIN_AVG_FPS and float(result["p99_frame_ms"]) <= PASS_MAX_P99_MS:
		return "PASS"
	return "FAIL"


static func _mean(values: PackedFloat32Array) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for value in values:
		total += value
	return total / float(values.size())
