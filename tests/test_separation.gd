extends RefCounted
## Push-apart maths on packed arrays, checked against a brute-force reference.


func _grid(points: Array[Vector2]) -> SpatialGrid:
	var grid := SpatialGrid.new(32.0, 1024.0)
	for point in points:
		grid.insert(RefCounted.new(), point)
	return grid


func _radii(count: int, value: float) -> PackedFloat32Array:
	var radii := PackedFloat32Array()
	for i in count:
		radii.append(value)
	return radii


func _serials(count: int) -> PackedInt32Array:
	var serials := PackedInt32Array()
	for i in count:
		serials.append(i)
	return serials


func run() -> Array:
	var failures: Array = []
	var out := PackedVector2Array()

	# 1. Two circles of radius 10, centres 10 apart: overlap 10, so pushes of 10 in opposite directions.
	var two_points: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(10.0, 0.0)]
	Separation.compute_into(_grid(two_points), _radii(2, 10.0), _serials(2), 10.0, 0, 1, 1.0, 1000.0, out)
	if out[0].distance_to(Vector2(-10.0, 0.0)) > 0.001 or out[1].distance_to(Vector2(10.0, 0.0)) > 0.001:
		failures.append("overlapping pair should be pushed (-10,0) and (10,0), got %s and %s" % [out[0], out[1]])

	# 2. Circles that only touch or do not overlap are left alone.
	var apart: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(25.0, 0.0)]
	Separation.compute_into(_grid(apart), _radii(2, 10.0), _serials(2), 10.0, 0, 1, 1.0, 1000.0, out)
	if out[0] != Vector2.ZERO or out[1] != Vector2.ZERO:
		failures.append("non-overlapping circles must not be pushed")

	# 3. Slicing: with first=0, stride=2 only items 0 and 2 get a result.
	# Not symmetric around the middle circle, or its two neighbours' pushes would cancel to zero.
	var three: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(5.0, 0.0), Vector2(12.0, 0.0)]
	Separation.compute_into(_grid(three), _radii(3, 10.0), _serials(3), 10.0, 0, 2, 1.0, 1000.0, out)
	if out[1] != Vector2.ZERO:
		failures.append("item 1 must be skipped when processing indices 0 and 2")
	if out[0] == Vector2.ZERO or out[2] == Vector2.ZERO:
		failures.append("items 0 and 2 should be pushed")
	Separation.compute_into(_grid(three), _radii(3, 10.0), _serials(3), 10.0, 1, 2, 1.0, 1000.0, out)
	if out[0] != Vector2.ZERO or out[2] != Vector2.ZERO or out[1] == Vector2.ZERO:
		failures.append("with first=1, only item 1 should be pushed")

	# 4. Exactly coincident circles get finite, non-zero, different pushes (deterministic from serials).
	var stacked: Array[Vector2] = [Vector2(7.0, 7.0), Vector2(7.0, 7.0)]
	var stacked_serials := PackedInt32Array([0, 90])
	Separation.compute_into(_grid(stacked), _radii(2, 10.0), stacked_serials, 10.0, 0, 1, 1.0, 1000.0, out)
	if is_nan(out[0].x) or is_nan(out[1].x) or out[0] == Vector2.ZERO or out[1] == Vector2.ZERO:
		failures.append("stacked circles must be pushed with finite values")
	if out[0].distance_to(out[1]) < 0.001:
		failures.append("stacked circles with different serials should be pushed in different directions")

	# 5. The step cap and strength are applied.
	Separation.compute_into(_grid(two_points), _radii(2, 10.0), _serials(2), 10.0, 0, 1, 0.5, 4.0, out)
	if absf(out[0].length() - 2.0) > 0.001:  # limit 4.0, times strength 0.5
		failures.append("push should be capped at max_step * strength = 2.0, got %s" % out[0].length())

	# 6. A random cluster must match a brute-force reference exactly.
	var rng := RunRng.new()
	rng.start(77)
	var cluster: Array[Vector2] = []
	var radii := PackedFloat32Array()
	for i in 200:
		cluster.append(Vector2(rng.float_range(-75.0, 75.0), rng.float_range(-75.0, 75.0)))
		radii.append(rng.float_range(8.0, 12.0))
	Separation.compute_into(_grid(cluster), radii, _serials(200), 12.0, 0, 1, 1.0, 100000.0, out)
	var worst := 0.0
	for i in 200:
		var expected := Vector2.ZERO
		for j in 200:
			if i == j:
				continue
			var offset: Vector2 = cluster[i] - cluster[j]
			var min_distance: float = radii[i] + radii[j]
			var distance_sq: float = offset.length_squared()
			if distance_sq < min_distance * min_distance and distance_sq >= 0.0001:
				var distance: float = sqrt(distance_sq)
				expected += offset / distance * (min_distance - distance)
		worst = maxf(worst, out[i].distance_to(expected))
	if worst > 0.01:
		failures.append("grid separation differs from brute force by up to %.4f" % worst)

	return failures
