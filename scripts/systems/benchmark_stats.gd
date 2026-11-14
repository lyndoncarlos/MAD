class_name BenchmarkStats
extends RefCounted
## Turns raw samples into the numbers that matter. Pure, so it is unit tested.

## Pass thresholds for the M2 gate (at 800 enemies).
const PASS_MIN_AVG_FPS := 55.0
const PASS_MAX_P99_MS := 25.0
## The game must run at (nearly) real-time speed. Below this the simulation is falling behind
## and the game would feel like slow motion even if the frame rate looks acceptable.
const PASS_MIN_SIM_SPEED := 0.95


## frame_ms: one sample per rendered frame, in milliseconds.
static func summarize_frames(frame_ms: PackedFloat32Array) -> Dictionary:
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
	}


## Average and worst value of a list of millisecond samples.
static func avg_max(samples_ms: PackedFloat32Array) -> Dictionary:
	var worst := 0.0
	for value in samples_ms:
		worst = maxf(worst, value)
	return {"avg": snappedf(_mean(samples_ms), 0.001), "max": snappedf(worst, 0.001)}


## Physics ticks that ran divided by the ticks that should have run in real time.
## 1.0 means real time; 0.5 means the game ran at half speed.
static func sim_speed_ratio(ticks_run: int, measured_seconds: float, ticks_per_second: float) -> float:
	var expected: float = measured_seconds * ticks_per_second
	if expected <= 0.0:
		return 0.0
	return snappedf(float(ticks_run) / expected, 0.001)


## `sorted` must be ascending. q is 0.0 to 1.0. Nearest-rank method.
static func percentile(sorted: Array, q: float) -> float:
	if sorted.is_empty():
		return 0.0
	var rank: int = clampi(ceili(q * float(sorted.size())) - 1, 0, sorted.size() - 1)
	return sorted[rank]


static func verdict(result: Dictionary) -> String:
	var speed: float = float(result.get("sim_speed_ratio", 1.0))
	if float(result["avg_fps"]) >= PASS_MIN_AVG_FPS and float(result["p99_frame_ms"]) <= PASS_MAX_P99_MS and speed >= PASS_MIN_SIM_SPEED:
		return "PASS"
	return "FAIL"


static func _mean(values: PackedFloat32Array) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for value in values:
		total += value
	return total / float(values.size())
