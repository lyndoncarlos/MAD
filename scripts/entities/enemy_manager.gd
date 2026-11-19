class_name EnemyManager
extends Node2D
## Owns every enemy. One loop updates them all (no per-node _physics_process), nodes are
## recycled through a pool, enemies push each other apart so hordes do not collapse into
## one dot, and a spatial grid answers "who is near here?" cheaply.
## Must sit at the world origin: enemy positions are world positions.
##
## Cost control (800 enemies must fit in a 16.7 ms physics tick):
##  - the grid is rebuilt every GRID_REBUILD_EVERY ticks (positions may be one tick stale)
##  - separation handles 1/SEPARATION_SLICES of the enemies per tick, with proportionally
##    stronger pushes, so every enemy is still corrected regularly
##  - counts are kept incrementally and the dead-enemy sweep only runs when something died
##
## Far-off enemies are RECYCLED, never despawned: an enemy that falls more than
## RECYCLE_DISTANCE behind the hero is reset and re-placed near the hero, so the horde stays
## in contact. It is not a kill: no died signal, no XP or drops, and the alive counts do not
## change. Where it lands comes from `recycle_picker`, which the run scene points at the
## seeded spawn stream (the manager itself has no randomness). Without a picker, nothing
## is recycled.

signal enemy_died(enemy: Enemy)

const CELL_SIZE := 32.0
const GRID_HALF_EXTENT := 3072.0
const GRID_REBUILD_EVERY := 2
const SEPARATION_SLICES := 2
## Fraction of the overlap resolved per correction, and a cap on how far one enemy is pushed.
const SEPARATION_STRENGTH := 0.5
const SEPARATION_MAX_STEP := 6.0
## An enemy farther than this from the hero is recycled. Keep it well outside the spawn ring
## (760) and the screen, and inside the grid (GRID_HALF_EXTENT).
const RECYCLE_DISTANCE := 1400.0
## The distance check runs every N ticks (about 6 times a second at 60 Hz).
const RECYCLE_CHECK_EVERY := 10

var hero: Hero
## Callable(enemy_data: EnemyData) -> Vector2: a world position near the hero for a recycled
## enemy. Set by the run scene. Leave unset to disable recycling.
var recycle_picker: Callable = Callable()
## How many enemies were recycled so far (for logs and tests).
var recycled_count: int = 0
var grid: SpatialGrid = SpatialGrid.new(CELL_SIZE, GRID_HALF_EXTENT)
## How many Enemy nodes were ever created. Stays flat once the pool is warm.
var total_created: int = 0

## Microseconds spent in each phase of the most recent step (for the benchmark and profiling).
var last_enemy_usec: int = 0
var last_separation_usec: int = 0
var last_release_usec: int = 0
var last_grid_usec: int = 0
var last_total_usec: int = 0

var _active: Array[Enemy] = []
var _pool: Array[Enemy] = []
var _alive: int = 0
var _alive_by_id: Dictionary = {}
var _dead_pending: bool = false
var _next_serial: int = 0
var _tick: int = 0

var _radii: PackedFloat32Array = PackedFloat32Array()
var _serials: PackedInt32Array = PackedInt32Array()
var _pushes: PackedVector2Array = PackedVector2Array()
var _grid_max_radius: float = 1.0


func setup(target: Hero) -> void:
	hero = target


func spawn(enemy_data: EnemyData, where: Vector2) -> Enemy:
	var enemy: Enemy
	if _pool.is_empty():
		enemy = Enemy.new()
		enemy.died.connect(_on_enemy_died)
		add_child(enemy)
		total_created += 1
	else:
		enemy = _pool.pop_back()
	enemy.reset(enemy_data, hero)
	enemy.serial = _next_serial
	_next_serial += 1
	enemy.position = where
	_active.append(enemy)
	_alive += 1
	_alive_by_id[enemy_data.id] = _alive_by_id.get(enemy_data.id, 0) + 1
	return enemy


## Enemies currently in play (not dying).
func alive_count() -> int:
	return _alive


## enemy id -> how many are alive (a copy; safe to modify).
func alive_counts() -> Dictionary:
	return _alive_by_id.duplicate()


func pool_size() -> int:
	return _pool.size()


func _physics_process(delta: float) -> void:
	step(delta)


## One simulation tick. Public so tests and benchmarks can drive it without a scene tree.
func step(delta: float) -> void:
	var t0: int = Time.get_ticks_usec()
	for enemy in _active:
		enemy.step(delta)
	if _tick % RECYCLE_CHECK_EVERY == 0:
		_recycle_far()
	var t1: int = Time.get_ticks_usec()
	_separate()
	var t2: int = Time.get_ticks_usec()
	if _dead_pending:
		_release_dead()
	var t3: int = Time.get_ticks_usec()
	if _tick % GRID_REBUILD_EVERY == 0:
		_rebuild_grid()
	var t4: int = Time.get_ticks_usec()
	_tick += 1

	last_enemy_usec = t1 - t0
	last_separation_usec = t2 - t1
	last_release_usec = t3 - t2
	last_grid_usec = t4 - t3
	last_total_usec = t4 - t0


## Resets every live enemy that is too far from the hero and puts it back near the hero.
## Iterates in spawn order, so the seeded picker is consulted in a repeatable order.
func _recycle_far() -> void:
	if not recycle_picker.is_valid() or hero == null or not is_instance_valid(hero):
		return
	var limit_sq: float = RECYCLE_DISTANCE * RECYCLE_DISTANCE
	var hero_position: Vector2 = hero.position
	for enemy in _active:
		if enemy.is_dying:
			continue
		if enemy.position.distance_squared_to(hero_position) <= limit_sq:
			continue
		var where: Vector2 = recycle_picker.call(enemy.data)
		enemy.reset(enemy.data, hero)
		enemy.serial = _next_serial
		_next_serial += 1
		enemy.position = where
		recycled_count += 1


func _separate() -> void:
	var count: int = grid.count()
	if count < 2:
		return
	var slice: int = _tick % SEPARATION_SLICES
	Separation.compute_into(
		grid, _radii, _serials, _grid_max_radius,
		slice, SEPARATION_SLICES,
		SEPARATION_STRENGTH * float(SEPARATION_SLICES), SEPARATION_MAX_STEP,
		_pushes
	)
	var i: int = slice
	while i < count:
		var push: Vector2 = _pushes[i]
		if push != Vector2.ZERO:
			var enemy: Enemy = grid.item_at(i)
			# The grid can be a tick old: only push the same enemy that was indexed.
			if enemy.serial == _serials[i] and enemy.is_targetable():
				enemy.position += push
		i += SEPARATION_SLICES


func _release_dead() -> void:
	_dead_pending = false
	var still_active: Array[Enemy] = []
	for enemy in _active:
		if enemy.is_dying:
			enemy.visible = false
			_pool.append(enemy)
		else:
			still_active.append(enemy)
	_active = still_active


func _rebuild_grid() -> void:
	grid.clear()
	_radii.clear()
	_serials.clear()
	_grid_max_radius = 1.0
	for enemy in _active:
		if enemy.is_targetable():
			grid.insert(enemy, enemy.position)
			_radii.append(enemy.data.radius)
			_serials.append(enemy.serial)
			_grid_max_radius = maxf(_grid_max_radius, enemy.data.radius)


func _on_enemy_died(enemy: Enemy) -> void:
	_alive -= 1
	_alive_by_id[enemy.data.id] = _alive_by_id.get(enemy.data.id, 1) - 1
	_dead_pending = true
	enemy_died.emit(enemy)
