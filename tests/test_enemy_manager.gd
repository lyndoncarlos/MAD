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
	var victim: Enemy = counting.spawn(grunt, Vector2(900.0, 900.0))
	victim.take_damage(9999.0)
	if counting.alive_counts().get(&"grunt", 0) != 3 or counting.alive_count() != 5:
		failures.append("alive counts must drop as soon as an enemy dies: %s / %d" % [counting.alive_counts(), counting.alive_count()])

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
	burrow.step(0.016)  # the grid refreshes every 2nd tick, so allow one more
	burrow.grid.query_circle(Vector2(300.0, 300.0), 50.0, near)
	if near.size() != 1:
		failures.append("an emerged enemy should appear in the grid, found %d" % near.size())

	# 9. Far-off enemies are recycled (reset and re-placed), never despawned or counted as kills.
	var rec: EnemyManager = EnemyManager.new()
	var rec_hero := Hero.new()
	_to_free.append(rec_hero)
	_to_free.append(rec)
	rec_hero.position = Vector2.ZERO
	rec.setup(rec_hero)
	var picks: Array = []
	rec.recycle_picker = func(_d: EnemyData) -> Vector2:
		picks.append(1)
		return Vector2(300.0, 0.0)
	var rec_deaths: Array = []
	rec.enemy_died.connect(func(_e: Enemy) -> void: rec_deaths.append(1))
	var near_enemy: Enemy = rec.spawn(grunt, Vector2(100.0, 200.0))
	var far_enemy: Enemy = rec.spawn(grunt, Vector2(EnemyManager.RECYCLE_DISTANCE + 500.0, 0.0))
	far_enemy.hp = 3.0
	var far_serial: int = far_enemy.serial
	for i in EnemyManager.RECYCLE_CHECK_EVERY:
		rec.step(0.016)
	if picks.size() != 1 or rec.recycled_count != 1:
		failures.append("exactly one far enemy should be recycled, picker calls=%d recycled=%d" % [picks.size(), rec.recycled_count])
	if far_enemy.position.distance_to(Vector2(300.0, 0.0)) > 20.0:  # separation may nudge it
		failures.append("the far enemy should be re-placed near the hero, it is at %s" % far_enemy.position)
	if far_enemy.hp != grunt.max_hp or far_enemy.serial == far_serial:
		failures.append("a recycled far enemy must be reset with a new serial")
	if near_enemy.position.distance_to(Vector2(100.0, 200.0)) > 20.0:
		failures.append("an enemy inside the range must not be moved")
	if rec.alive_count() != 2 or rec.total_created != 2 or rec.pool_size() != 0:
		failures.append("recycling must not change counts: alive=%d created=%d pool=%d" % [rec.alive_count(), rec.total_created, rec.pool_size()])
	if rec_deaths.size() != 0:
		failures.append("recycling is not a kill: no died signal expected, got %d" % rec_deaths.size())

	# 10. Without a picker nothing is recycled.
	var idle: EnemyManager = EnemyManager.new()
	var idle_hero := Hero.new()
	_to_free.append(idle_hero)
	_to_free.append(idle)
	idle.setup(idle_hero)
	var stray: Enemy = idle.spawn(grunt, Vector2(EnemyManager.RECYCLE_DISTANCE + 500.0, 0.0))
	for i in EnemyManager.RECYCLE_CHECK_EVERY:
		idle.step(0.016)
	if stray.position.x < EnemyManager.RECYCLE_DISTANCE or idle.recycled_count != 0:
		failures.append("with no recycle_picker the enemy must stay where it is")

	# 11. Dying enemies are never recycled.
	var dying_mgr: EnemyManager = EnemyManager.new()
	var dying_hero := Hero.new()
	_to_free.append(dying_hero)
	_to_free.append(dying_mgr)
	dying_mgr.setup(dying_hero)
	dying_mgr.recycle_picker = func(_d: EnemyData) -> Vector2: return Vector2(300.0, 0.0)
	var doomed: Enemy = dying_mgr.spawn(grunt, Vector2(EnemyManager.RECYCLE_DISTANCE + 500.0, 0.0))
	doomed.take_damage(9999.0)
	for i in EnemyManager.RECYCLE_CHECK_EVERY:
		dying_mgr.step(0.016)
	if dying_mgr.recycled_count != 0:
		failures.append("a dying enemy must not be recycled")

	# 12. A charging elite slams lesser enemies once: friendly damage and knockback, never other elites.
	var slam_mgr: EnemyManager = _manager()
	var slam_boss_data: EnemyData = _data("slam_boss", 0.0, 26.0)
	slam_boss_data.is_elite = true
	slam_boss_data.max_hp = 500.0
	slam_boss_data.slam_damage = 6.0
	slam_boss_data.slam_knockback = 300.0
	var slam_boss: Enemy = slam_mgr.spawn(slam_boss_data, Vector2.ZERO)
	var slam_victim: Enemy = slam_mgr.spawn(grunt, Vector2(30.0, 0.0))
	var slam_bystander: Enemy = slam_mgr.spawn(grunt, Vector2(400.0, 0.0))
	var slam_other_elite: Enemy = slam_mgr.spawn(slam_boss_data, Vector2(-30.0, 0.0))
	slam_mgr.step(0.016)  # builds the grid
	slam_boss.is_charging = true
	for i in 6:
		slam_mgr.step(0.016)
	if slam_victim.hp != 4.0:
		failures.append("slam should hit the slam_victim exactly once for its damage (hp %s)" % slam_victim.hp)
	if slam_victim.knockback == Vector2.ZERO and slam_victim.position.x <= 30.0:
		failures.append("slam should knock the slam_victim away")
	if slam_bystander.hp != 10.0:
		failures.append("enemies out of reach must not be slammed")
	if slam_other_elite.hp != 500.0:
		failures.append("elites must not slam each other")
	slam_boss.is_charging = false
	var slam_calm_hp: float = slam_victim.hp
	for i in 6:
		slam_mgr.step(0.016)
	if slam_victim.hp != slam_calm_hp:
		failures.append("no slam damage when the elite is not charging")

	for node in _to_free:
		node.free()
	return failures
