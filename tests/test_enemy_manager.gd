extends RefCounted
## Pooling, counting, separation and burrow visibility, driven without a scene tree.


func _data(id: String, speed: float = 0.0, radius: float = 10.0) -> EnemyData:
	var d := EnemyData.new()
	d.id = StringName(id)
	d.display_name = id
	d.max_hp = 10.0
	d.move_speed = speed
	d.contact_damage = 0.0
	d.radius = radius
	d.spawn_style = EnemyData.SpawnStyle.RING
	return d


var _to_free: Array = []


func _manager() -> EnemyManager:
	var manager := EnemyManager.new()
	var hero := Hero.new()
	_to_free.append(hero)
	_to_free.append(manager)
	hero.position = Vector2(5000.0, 0.0)  # far away, so nothing reaches it
	manager.setup(hero)
	return manager


func run() -> Array:
	var failures: Array = []
	var grunt: EnemyData = _data("grunt")

	# 1. Spawning creates nodes and counts them.
	var manager: EnemyManager = _manager()
	var spawned: Array[Enemy] = []
	for i in 20:
		spawned.append(manager.spawn(grunt, Vector2(float(i) * 100.0, 0.0)))
	var first_serial: int = spawned[0].serial
	if manager.alive_count() != 20 or manager.total_created != 20:
		failures.append("expected 20 alive / 20 created, got %d / %d" % [manager.alive_count(), manager.total_created])

	# 2. Killed enemies leave play and go to the pool.
	var death_log: Array = []  # a lambda copies ints, but shares Arrays
	manager.enemy_died.connect(func(_e: Enemy) -> void: death_log.append(1))
	for i in 5:
		spawned[i].take_damage(9999.0)
	if manager.alive_count() != 15:
		failures.append("alive_count should drop to 15 immediately, got %d" % manager.alive_count())
	manager.step(0.016)
	if death_log.size() != 5:
		failures.append("expected 5 died signals, got %d" % death_log.size())
	if manager.pool_size() != 5:
		failures.append("pool should hold 5 recycled enemies, has %d" % manager.pool_size())

	# 3. New spawns reuse pooled nodes instead of creating new ones.
	for i in 5:
		manager.spawn(grunt, Vector2(float(i) * 100.0, 300.0))
	if manager.total_created != 20:
		failures.append("recycled spawns created new nodes (total_created=%d)" % manager.total_created)
	if manager.alive_count() != 20 or manager.pool_size() != 0:
		failures.append("after reuse: expected 20 alive and an empty pool, got %d and %d" % [manager.alive_count(), manager.pool_size()])

	# 4. A recycled enemy is fully reset (fresh HP, alive, visible, new serial).
	var first: Enemy = spawned[0]
	var reused: Enemy = null
	for enemy in manager._active:
		if enemy == first:
			reused = enemy
	if reused == null:
		failures.append("the first enemy should have been recycled back into play")
	else:
		if reused.hp != grunt.max_hp or reused.is_dying or not reused.visible:
			failures.append("a recycled enemy was not reset")
		if reused.serial == first_serial:
			failures.append("a recycled enemy must get a new serial")

	# 5. Counts per enemy id.
	var counting: EnemyManager = _manager()
	var other: EnemyData = _data("other")
	for i in 3:
		counting.spawn(grunt, Vector2(float(i) * 80.0, 0.0))
	for i in 2:
		counting.spawn(other, Vector2(float(i) * 80.0, 400.0))
	var counts: Dictionary = counting.alive_counts()
	if counts.get(&"grunt", 0) != 3 or counts.get(&"other", 0) != 2:
		failures.append("alive_counts wrong: %s" % counts)

	# 6. Separation: two enemies spawned almost on top of each other end up apart.
	var sep: EnemyManager = _manager()
	var a: Enemy = sep.spawn(grunt, Vector2(0.0, 0.0))
	var b: Enemy = sep.spawn(grunt, Vector2(0.5, 0.0))
	for i in 20:
		sep.step(0.016)
	var gap: float = a.position.distance_to(b.position)
	if gap < 19.0:  # radii are 10 each
		failures.append("overlapping enemies should be pushed apart to about 20 px, gap is %.2f" % gap)

	# 7. Separation also handles exactly coincident enemies without NaNs.
	var stacked: EnemyManager = _manager()
	var c: Enemy = stacked.spawn(grunt, Vector2.ZERO)
	var d: Enemy = stacked.spawn(grunt, Vector2.ZERO)
	for i in 20:
		stacked.step(0.016)
	if is_nan(c.position.x) or is_nan(d.position.x) or c.position.distance_to(d.position) < 19.0:
		failures.append("exactly stacked enemies should separate cleanly (gap %.2f)" % c.position.distance_to(d.position))

	# 8. Burrowed enemies are not in the grid until they emerge.
	var burrow_data: EnemyData = _data("burrower")
	burrow_data.spawn_style = EnemyData.SpawnStyle.BURROW
	burrow_data.burrow_telegraph_seconds = 0.9
	burrow_data.emerge_burst_seconds = 0.0
	var burrow: EnemyManager = _manager()
	burrow.spawn(burrow_data, Vector2(300.0, 300.0))
	var near: Array = []
	burrow.step(0.016)
	burrow.grid.query_circle(Vector2(300.0, 300.0), 50.0, near)
	if near.size() != 0:
		failures.append("a burrowed enemy must not be targetable through the grid")
	burrow.step(1.0)  # past the 0.9 s warning
	burrow.grid.query_circle(Vector2(300.0, 300.0), 50.0, near)
	if near.size() != 1:
		failures.append("an emerged enemy should appear in the grid, found %d" % near.size())

	for node in _to_free:
		node.free()
	return failures
