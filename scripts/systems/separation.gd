class_name Separation
extends RefCounted
## Computes push-apart displacements for overlapping circles using a SpatialGrid.
## Works on packed arrays (much faster in GDScript than reading properties from objects)
## and can process just a slice of the items per call (every `stride`-th item from `first`),
## so the manager can spread the work across ticks.


## Fills `out` with one displacement per grid item (zero for items not processed or not
## overlapping). radii[i] and serials[i] describe grid item i. `serials` only picks a
## deterministic direction for items sitting exactly on top of each other.
static func compute_into(
	grid: SpatialGrid,
	radii: PackedFloat32Array,
	serials: PackedInt32Array,
	max_radius: float,
	first: int,
	stride: int,
	strength: float,
	max_step: float,
	out: PackedVector2Array
) -> void:
	var count: int = grid.count()
	out.resize(count)
	out.fill(Vector2.ZERO)
	var positions: PackedVector2Array = grid.positions()
	var head: PackedInt32Array = grid.head()
	var next: PackedInt32Array = grid.next()
	var cols: int = grid.cols()

	var i: int = first
	while i < count:
		var pos: Vector2 = positions[i]
		var radius_i: float = radii[i]
		var reach: float = radius_i + max_radius
		var x0: int = grid.col_of(pos.x - reach)
		var x1: int = grid.col_of(pos.x + reach)
		var y0: int = grid.row_of(pos.y - reach)
		var y1: int = grid.row_of(pos.y + reach)
		var push := Vector2.ZERO
		for cell_y in range(y0, y1 + 1):
			var row_start: int = cell_y * cols
			for cell_x in range(x0, x1 + 1):
				var j: int = head[row_start + cell_x]
				while j != -1:
					if j != i:
						var offset: Vector2 = pos - positions[j]
						var min_distance: float = radius_i + radii[j]
						var distance_sq: float = offset.length_squared()
						if distance_sq < min_distance * min_distance:
							if distance_sq < 0.0001:
								push += Vector2.from_angle(deg_to_rad(float(serials[i] % 360))) * min_distance
							else:
								var distance: float = sqrt(distance_sq)
								push += offset / distance * (min_distance - distance)
					j = next[j]
		if push != Vector2.ZERO:
			out[i] = push.limit_length(max_step) * strength
		i += stride
