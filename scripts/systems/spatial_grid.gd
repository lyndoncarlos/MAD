class_name SpatialGrid
extends RefCounted
## Flat uniform grid for "what is near this point?" queries. Each cell holds a linked list
## stored in packed arrays (head per cell, next per item), so rebuilding and querying
## need no allocations and no Dictionary lookups. Rebuilt regularly by the enemy manager.
##
## The grid covers [-half_extent, +half_extent] on both axes. Items outside are placed in the
## nearest border cell, and queries clamp the same way, so results stay exact (every query
## ends with an exact distance test) even for points beyond the bounds.

var cell_size: float

var _half_extent: float
var _cols: int
var _head: PackedInt32Array = PackedInt32Array()
var _next: PackedInt32Array = PackedInt32Array()
var _items: Array = []
var _positions: PackedVector2Array = PackedVector2Array()


func _init(size: float = 32.0, half_extent: float = 3072.0) -> void:
	cell_size = maxf(size, 1.0)
	_half_extent = maxf(half_extent, cell_size)
	_cols = ceili(2.0 * _half_extent / cell_size) + 1
	_head.resize(_cols * _cols)
	_head.fill(-1)


func clear() -> void:
	_head.fill(-1)
	_next.clear()
	_items.clear()
	_positions.clear()


func count() -> int:
	return _items.size()


func insert(item: Object, where: Vector2) -> void:
	var index: int = _items.size()
	_items.append(item)
	_positions.append(where)
	var cell: int = row_of(where.y) * _cols + col_of(where.x)
	_next.append(_head[cell])
	_head[cell] = index


## Fills `out` (cleared first) with every item whose stored position is within `radius`
## of `center`. Exact circle test, not just "same cell".
func query_circle(center: Vector2, radius: float, out: Array) -> void:
	out.clear()
	var radius_sq: float = radius * radius
	var x0: int = col_of(center.x - radius)
	var x1: int = col_of(center.x + radius)
	var y0: int = row_of(center.y - radius)
	var y1: int = row_of(center.y + radius)
	for cell_y in range(y0, y1 + 1):
		var row_start: int = cell_y * _cols
		for cell_x in range(x0, x1 + 1):
			var index: int = _head[row_start + cell_x]
			while index != -1:
				if center.distance_squared_to(_positions[index]) <= radius_sq:
					out.append(_items[index])
				index = _next[index]


# --- accessors for tight loops (Separation) ---

func item_at(index: int) -> Object:
	return _items[index]


func positions() -> PackedVector2Array:
	return _positions


func head() -> PackedInt32Array:
	return _head


func next() -> PackedInt32Array:
	return _next


func cols() -> int:
	return _cols


func col_of(x: float) -> int:
	return clampi(floori((x + _half_extent) / cell_size), 0, _cols - 1)


func row_of(y: float) -> int:
	return clampi(floori((y + _half_extent) / cell_size), 0, _cols - 1)
