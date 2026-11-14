class_name EnemyManager
extends Node2D
## Owns every enemy. One loop updates them all (no per-node _physics_process), nodes are
## recycled through a pool (no allocation spikes), enemies push each other apart so hordes
## do not collapse into one dot, and a spatial grid answers "who is near here?" cheaply.
## Must sit at the world origin: enemy positions are world positions.

signal enemy_died(enemy: Enemy)

const CELL_SIZE := 64.0
## Fraction of the overlap resolved per frame, and a cap on how far one enemy is pushed.
const SEPARATION_STRENGTH := 0.5
const SEPARATION_MAX_STEP := 6.0

var hero: Hero
var grid: SpatialGrid = SpatialGrid.new(CELL_SIZE)
## How many Enemy nodes were ever created. Stays flat once the pool is warm.
var total_created: int = 0

var _active: Array[Enemy] = []
var _pool: Array[Enemy] = []
var _neighbors: Array = []
var _next_serial: int = 0


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
	return enemy


## Enemies currently in play (not dying).
func alive_count() -> int:
	var total := 0
	for enemy in _active:
		if not enemy.is_dying:
			total += 1
	return total


## enemy id -> how many are alive.
func alive_counts() -> Dictionary:
	var counts: Dictionary = {}
	for enemy in _active:
		if enemy.is_dying:
			continue
		counts[enemy.data.id] = counts.get(enemy.data.id, 0) + 1
	return counts


func pool_size() -> int:
	return _pool.size()


func _physics_process(delta: float) -> void:
	step(delta)


## One simulation tick. Public so tests and benchmarks can drive it without a scene tree.
func step(delta: float) -> void:
	for enemy in _active:
		enemy.step(delta)
	_separate()
	_release_dead()
	_rebuild_grid()


func _separate() -> void:
	for enemy in _active:
		if not enemy.is_targetable():
			continue
		grid.query_circle(enemy.position, enemy.data.radius + EnemyData.MAX_RADIUS, _neighbors)
		var push := Vector2.ZERO
		for item in _neighbors:
			var other: Enemy = item
			if other == enemy or not other.is_targetable():
				continue
			var offset: Vector2 = enemy.position - other.position
			var min_distance: float = enemy.data.radius + other.data.radius
			var distance_sq: float = offset.length_squared()
			if distance_sq >= min_distance * min_distance:
				continue
			if distance_sq < 0.0001:
				# Exactly on top of each other: pick a direction from the spawn serial (deterministic).
				push += Vector2.from_angle(deg_to_rad(float(enemy.serial % 360))) * min_distance
			else:
				var distance: float = sqrt(distance_sq)
				push += offset / distance * (min_distance - distance)
		if push != Vector2.ZERO:
			enemy.position += push.limit_length(SEPARATION_MAX_STEP) * SEPARATION_STRENGTH


func _release_dead() -> void:
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
	for enemy in _active:
		if enemy.is_targetable():
			grid.insert(enemy, enemy.position)


func _on_enemy_died(enemy: Enemy) -> void:
	enemy_died.emit(enemy)
