class_name SpatialGrid
extends RefCounted
## Uniform grid for "what is near this point?" queries. Rebuilt every frame by the
## enemy manager, so weapons check a handful of nearby cells instead of every enemy.

var cell_size: float

var _cells: Dictionary = {}  # Vector2i -> Array of indices into _items
var _items: Array = []
var _positions: PackedVector2Array = PackedVector2Array()


func _init(size: float = 64.0) -> void:
	cell_size = maxf(size, 1.0)


func clear() -> void:
	_cells.clear()
	_items.clear()
	_positions.clear()


func count() -> int:
	return _items.size()


func insert(item: Object, where: Vector2) -> void:
	var index: int = _items.size()
	_items.append(item)
	_positions.append(where)
	var key: Vector2i = _cell_of(where)
	if not _cells.has(key):
		_cells[key] = []
	(_cells[key] as Array).append(index)


## Fills `out` (cleared first) with every item whose stored position is within `radius`
## of `center`. Exact circle test, not just "same cell".
func query_circle(center: Vector2, radius: float, out: Array) -> void:
	out.clear()
	var radius_sq: float = radius * radius
	var low: Vector2i = _cell_of(center - Vector2(radius, radius))
	var high: Vector2i = _cell_of(center + Vector2(radius, radius))
	for cell_x in range(low.x, high.x + 1):
		for cell_y in range(low.y, high.y + 1):
			var key := Vector2i(cell_x, cell_y)
			if not _cells.has(key):
				continue
			for index in _cells[key]:
				if center.distance_squared_to(_positions[index]) <= radius_sq:
					out.append(_items[index])


func _cell_of(where: Vector2) -> Vector2i:
	return Vector2i(floori(where.x / cell_size), floori(where.y / cell_size))
