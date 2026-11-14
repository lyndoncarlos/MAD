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
	var summary: Dictionary = BenchmarkStats.summarize(frames, PackedFloat32Array([5.0, 7.0]), PackedFloat32Array([2.0, 4.0]))
	if summary["frames"] != 100:
		failures.append("frames should be 100")
	if absf(float(summary["avg_fps"]) - 59.0) > 1.5:
		failures.append("avg fps should be about 59, got %s" % summary["avg_fps"])
	if absf(float(summary["max_frame_ms"]) - 40.0) > 0.01:
		failures.append("max frame should be 40 ms")
	if absf(float(summary["avg_process_ms"]) - 6.0) > 0.01 or absf(float(summary["avg_physics_ms"]) - 3.0) > 0.01:
		failures.append("average process/physics ms wrong: %s / %s" % [summary["avg_process_ms"], summary["avg_physics_ms"]])
	if BenchmarkStats.verdict(summary) != "PASS":  # p99 = 16.67 (the single 40 ms hitch is the 100th sample)
		failures.append("a steady 60 fps run with one hitch should pass, got %s (p99 %s)" % [BenchmarkStats.verdict(summary), summary["p99_frame_ms"]])

	# Sustained slow frames must fail.
	var slow := PackedFloat32Array()
	for i in 100:
		slow.append(40.0)
	var slow_summary: Dictionary = BenchmarkStats.summarize(slow, PackedFloat32Array(), PackedFloat32Array())
	if BenchmarkStats.verdict(slow_summary) != "FAIL":
		failures.append("a steady 25 fps run must fail")

	# Empty input must not divide by zero.
	var empty: Dictionary = BenchmarkStats.summarize(PackedFloat32Array(), PackedFloat32Array(), PackedFloat32Array())
	if empty["frames"] != 0 or empty["avg_fps"] != 0.0:
		failures.append("empty samples should give zeros, not errors")

	return failures
