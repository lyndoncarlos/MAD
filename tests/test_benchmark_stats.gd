extends RefCounted
## The benchmark's maths must be right, or its PASS/FAIL means nothing.


func run() -> Array:
	var failures: Array = []

	# Percentiles of 1..100 (nearest-rank): p95 = 95, p99 = 99, p100 = 100.
	var sorted: Array = []
	for i in range(1, 101):
		sorted.append(float(i))
	if BenchmarkStats.percentile(sorted, 0.95) != 95.0:
		failures.append("p95 of 1..100 should be 95, got %s" % BenchmarkStats.percentile(sorted, 0.95))
	if BenchmarkStats.percentile(sorted, 0.99) != 99.0:
		failures.append("p99 of 1..100 should be 99, got %s" % BenchmarkStats.percentile(sorted, 0.99))
	if BenchmarkStats.percentile(sorted, 1.0) != 100.0:
		failures.append("p100 should be the maximum")
	if BenchmarkStats.percentile([], 0.99) != 0.0:
		failures.append("percentile of nothing should be 0")
	if BenchmarkStats.percentile([7.0], 0.99) != 7.0:
		failures.append("percentile of one sample should be that sample")

	# A steady 16.67 ms (60 fps) with one 40 ms hitch in 100 frames.
	var frames := PackedFloat32Array()
	for i in 99:
		frames.append(16.67)
	frames.append(40.0)
	var summary: Dictionary = BenchmarkStats.summarize_frames(frames)
	if summary["frames"] != 100:
		failures.append("frames should be 100")
	if absf(float(summary["avg_fps"]) - 59.0) > 1.5:
		failures.append("avg fps should be about 59, got %s" % summary["avg_fps"])
	if absf(float(summary["max_frame_ms"]) - 40.0) > 0.01:
		failures.append("max frame should be 40 ms")
	if BenchmarkStats.verdict(summary) != "PASS":  # no sim_speed_ratio given: treated as real time
		failures.append("a steady 60 fps run with one hitch should pass, got %s (p99 %s)" % [BenchmarkStats.verdict(summary), summary["p99_frame_ms"]])

	# Sustained slow frames must fail.
	var slow := PackedFloat32Array()
	for i in 100:
		slow.append(40.0)
	if BenchmarkStats.verdict(BenchmarkStats.summarize_frames(slow)) != "FAIL":
		failures.append("a steady 25 fps run must fail")

	# Empty input must not divide by zero.
	var empty: Dictionary = BenchmarkStats.summarize_frames(PackedFloat32Array())
	if empty["frames"] != 0 or empty["avg_fps"] != 0.0:
		failures.append("empty samples should give zeros, not errors")

	# Phase stats: average and worst of a list of timings.
	var phase: Dictionary = BenchmarkStats.avg_max(PackedFloat32Array([2.0, 4.0, 6.0]))
	if absf(float(phase["avg"]) - 4.0) > 0.001 or absf(float(phase["max"]) - 6.0) > 0.001:
		failures.append("avg_max([2,4,6]) should be 4 and 6, got %s" % phase)
	var none: Dictionary = BenchmarkStats.avg_max(PackedFloat32Array())
	if none["avg"] != 0.0 or none["max"] != 0.0:
		failures.append("avg_max of nothing should be zeros")

	# Simulation speed: 60 ticks/s for 20 s should be 1200 ticks.
	if absf(BenchmarkStats.sim_speed_ratio(1200, 20.0, 60.0) - 1.0) > 0.001:
		failures.append("1200 ticks in 20 s at 60 tps should be ratio 1.0")
	if absf(BenchmarkStats.sim_speed_ratio(600, 20.0, 60.0) - 0.5) > 0.001:
		failures.append("600 ticks in 20 s at 60 tps should be ratio 0.5")
	if BenchmarkStats.sim_speed_ratio(100, 0.0, 60.0) != 0.0:
		failures.append("zero measured time should give ratio 0, not a crash")

	# A fast-looking run that fell behind real time (slow motion) must still FAIL.
	var slow_motion := {"avg_fps": 120.0, "p99_frame_ms": 9.0, "sim_speed_ratio": 0.5}
	if BenchmarkStats.verdict(slow_motion) != "FAIL":
		failures.append("a run with sim speed 0.5 must fail even at high fps")
	var real_time := {"avg_fps": 120.0, "p99_frame_ms": 9.0, "sim_speed_ratio": 0.99}
	if BenchmarkStats.verdict(real_time) != "PASS":
		failures.append("a run at sim speed 0.99 with good frames should pass")

	return failures
