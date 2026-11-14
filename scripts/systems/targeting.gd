class_name Targeting
extends RefCounted
## Enemy queries, answered by the manager's spatial grid.


static func nearest_enemy(manager: EnemyManager, origin: Vector2, max_range: float) -> Enemy:
	if manager == null:
		return null
	var candidates: Array = []
	manager.grid.query_circle(origin, max_range, candidates)
	var best: Enemy = null
	var best_dist_sq: float = INF
	for item in candidates:
		var enemy: Enemy = item
		if not enemy.is_targetable():
			continue
		var dist_sq: float = origin.distance_squared_to(enemy.position)
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best = enemy
	return best
