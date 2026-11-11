class_name Targeting
extends RefCounted
## Simple enemy queries. Fine for M1; M2 replaces the linear scan with a spatial grid.


static func nearest_enemy(tree: SceneTree, origin: Vector2, max_range: float) -> Enemy:
	var best: Enemy = null
	var best_dist_sq: float = max_range * max_range
	for node in tree.get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		if enemy == null or enemy.is_dying:
			continue
		var dist_sq: float = origin.distance_squared_to(enemy.global_position)
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best = enemy
	return best
