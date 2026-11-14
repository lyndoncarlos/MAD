extends RefCounted
## The grid must return exactly what a brute-force scan would, including out-of-bounds points.


func _indices(found: Array) -> Array:
	var result: Array = []
	for item in found:
		result.append(item.get_meta("index"))
	result.sort()
	return result


func _make(grid: SpatialGrid, points: Array[Vector2]) -> void:
	for i in points.size():
		var item := RefCounted.new()
		item.set_meta("index", i)
		_items.append(item)
		grid.insert(item, points[i])


var _items: Array = []


func run() -> Array:
	var failures: Array = []
	var rng := RunRng.new()
	rng.start(4242)
	var found: Array = []

	# 1. 400 random points inside the grid (half extent 1024), including negative coordinates.
	var grid := SpatialGrid.new(64.0, 1024.0)
	var points: Array[Vector2] = []
	for i in 400:
		points.append(Vector2(rng.float_range(-500.0, 500.0), rng.float_range(-500.0, 500.0)))
	_make(grid, points)
	if grid.count() != 400:
		failures.append("grid should hold 400 items, has %d" % grid.count())
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

	# 2. Points far OUTSIDE the grid bounds must still be found correctly (they share border cells).
	var wide := SpatialGrid.new(64.0, 512.0)
	var wide_points: Array[Vector2] = []
	_items.clear()
	for i in 300:
		wide_points.append(Vector2(rng.float_range(-3000.0, 3000.0), rng.float_range(-3000.0, 3000.0)))
	_make(wide, wide_points)
	for q in 100:
		var center := Vector2(rng.float_range(-3200.0, 3200.0), rng.float_range(-3200.0, 3200.0))
		var radius: float = rng.float_range(5.0, 900.0)
		wide.query_circle(center, radius, found)
		var expected: Array = []
		for i in 300:
			if center.distance_squared_to(wide_points[i]) <= radius * radius:
				expected.append(i)
		if _indices(found) != expected:
			failures.append("out-of-bounds query %d differs from brute force: got %d, expected %d" % [q, found.size(), expected.size()])
			break

	# 3. A point exactly on a cell border is found with radius 0, and not found from 1 px away.
	var border := SpatialGrid.new(64.0, 1024.0)
	_items.clear()
	var border_points: Array[Vector2] = [Vector2(64.0, 64.0)]
	_make(border, border_points)
	border.query_circle(Vector2(64.0, 64.0), 0.0, found)
	if found.size() != 1:
		failures.append("a point on a cell border should be found with radius 0")
	border.query_circle(Vector2(65.0, 64.0), 0.0, found)
	if found.size() != 0:
		failures.append("a point 1 px away should not be found with radius 0")

	# 4. The query output array is cleared each time.
	found.append("stale")
	grid.query_circle(Vector2(9999.0, 9999.0), 10.0, found)
	if found.size() != 0:
		failures.append("query_circle must clear the output array")

	# 5. clear() empties everything, and the grid is reusable afterwards.
	grid.clear()
	grid.query_circle(Vector2.ZERO, 5000.0, found)
	if grid.count() != 0 or found.size() != 0:
		failures.append("clear() should remove every item")
	_items.clear()
	var again: Array[Vector2] = [Vector2(10.0, 10.0)]
	_make(grid, again)
	grid.query_circle(Vector2(10.0, 10.0), 1.0, found)
	if found.size() != 1:
		failures.append("the grid should work again after clear()")

	return failures
