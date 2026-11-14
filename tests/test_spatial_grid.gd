extends RefCounted
## The grid must return exactly what a brute-force scan would.


func _indices(found: Array) -> Array:
	var result: Array = []
	for item in found:
		result.append(item.get_meta("index"))
	result.sort()
	return result


func run() -> Array:
	var failures: Array = []
	var rng := RunRng.new()
	rng.start(4242)

	# 400 random points, including negative coordinates.
	var grid := SpatialGrid.new(64.0)
	var items: Array = []
	var points: Array[Vector2] = []
	for i in 400:
		var item := RefCounted.new()
		item.set_meta("index", i)
		var point := Vector2(rng.float_range(-500.0, 500.0), rng.float_range(-500.0, 500.0))
		items.append(item)
		points.append(point)
		grid.insert(item, point)
	if grid.count() != 400:
		failures.append("grid should hold 400 items, has %d" % grid.count())

	# 100 random circle queries must match a brute-force scan exactly.
	var found: Array = []
	for q in 100:
		var center := Vector2(rng.float_range(-550.0, 550.0), rng.float_range(-550.0, 550.0))
		var radius: float = rng.float_range(5.0, 220.0)
		grid.query_circle(center, radius, found)
		var expected: Array = []
		for i in 400:
			if center.distance_squared_to(points[i]) <= radius * radius:
				expected.append(i)
		if _indices(found) != expected:
			failures.append("query %d (center %s, radius %.1f) differs from brute force: got %d, expected %d" % [q, center, radius, found.size(), expected.size()])
			break

	# A point exactly on a cell border is found with radius 0, and not found from 1 px away.
	var border := SpatialGrid.new(64.0)
	var border_item := RefCounted.new()
	border_item.set_meta("index", 0)
	border.insert(border_item, Vector2(64.0, 64.0))
	border.query_circle(Vector2(64.0, 64.0), 0.0, found)
	if found.size() != 1:
		failures.append("a point on a cell border should be found with radius 0")
	border.query_circle(Vector2(65.0, 64.0), 0.0, found)
	if found.size() != 0:
		failures.append("a point 1 px away should not be found with radius 0")

	# The query output array is cleared each time (no leftovers from the previous query).
	found.append("stale")
	grid.query_circle(Vector2(9999.0, 9999.0), 10.0, found)
	if found.size() != 0:
		failures.append("query_circle must clear the output array")

	# clear() empties everything.
	grid.clear()
	grid.query_circle(Vector2.ZERO, 5000.0, found)
	if grid.count() != 0 or found.size() != 0:
		failures.append("clear() should remove every item")

	return failures
