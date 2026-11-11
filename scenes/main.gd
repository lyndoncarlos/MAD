class_name RunWorld
extends Node2D
## M1 run controller: owns the hero, spawner, pickups and UI, and wires the core loop:
## kill -> Sinag drops -> pick up -> level up -> choose upgrade -> repeat -> die -> restart.
##
## Fixed seed:  godot --path . -- --seed=12345
## The world root must stay at the origin (projectiles use world coordinates).

const HERO_SCENE: PackedScene = preload("res://scenes/heroes/hero.tscn")
const MAP_SCENE: PackedScene = preload("res://scenes/maps/test_map.tscn")
const MAP_HALF_SIZE := 2048.0
const SPAWN_RING_RADIUS := 760.0
const REST_HEAL := 30.0
const LEVEL_CURVE_ID := &"level_curve_default"
const SPAWN_CURVE_ID := &"chapter_01"

@export var hero_id: StringName = &"tala"

var run_time: float = 0.0
var hero: Hero
var run_state: RunState

var _planner: SpawnPlanner
var _hud: Hud
var _level_up_menu: LevelUpMenu
var _game_over_screen: GameOverScreen
var _weapon_pool: Array = []
var _passive_pool: Array = []
var _menu_open: bool = false
var _game_over: bool = false


func _ready() -> void:
	InputSetup.ensure_actions()

	var run_seed: int = RngService.start_run(_resolve_seed())
	var hero_data := DataRegistry.get_data(&"heroes", hero_id) as HeroData
	var level_curve := DataRegistry.get_data(&"level_curves", LEVEL_CURVE_ID) as LevelCurveData
	var spawn_curve := DataRegistry.get_data(&"spawn_curves", SPAWN_CURVE_ID) as SpawnCurveData
	if hero_data == null or level_curve == null or spawn_curve == null:
		push_error("[RunWorld] missing required data; cannot start the run")
		return

	run_state = RunState.new(level_curve)
	_planner = SpawnPlanner.new(spawn_curve)
	_weapon_pool = _weapons_for_pool()
	_passive_pool = _passives_for_pool()
	RunLogger.start_run(hero_id, run_seed)

	add_child(MAP_SCENE.instantiate())
	hero = HERO_SCENE.instantiate() as Hero
	hero.setup(hero_data)
	add_child(hero)
	hero.died.connect(_on_hero_died)
	_grant_weapon(hero_data.starting_weapon_id, 1)

	_build_ui()


func _physics_process(delta: float) -> void:
	if hero == null or _game_over:
		return
	run_time += delta
	hero.position = hero.position.clamp(
		Vector2(-MAP_HALF_SIZE, -MAP_HALF_SIZE), Vector2(MAP_HALF_SIZE, MAP_HALF_SIZE)
	)
	for enemy_id in _planner.plan(delta, run_time, _alive_counts()):
		_spawn_enemy(enemy_id)


# ---------------------------------------------------------------- spawning

func _alive_counts() -> Dictionary:
	var counts: Dictionary = {}
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		if enemy == null or enemy.is_dying:
			continue
		counts[enemy.data.id] = counts.get(enemy.data.id, 0) + 1
	return counts


func _spawn_enemy(enemy_id: StringName) -> void:
	var enemy_data := DataRegistry.get_data(&"enemies", enemy_id) as EnemyData
	if enemy_data == null:
		return
	var angle: float = RngService.float_range(0.0, TAU, RunRng.SPAWN)
	var position_on_ring: Vector2 = hero.global_position + SpawnPlanner.ring_offset(angle, SPAWN_RING_RADIUS)
	var enemy := Enemy.new()
	enemy.setup(enemy_data, hero)
	enemy.position = position_on_ring.clamp(
		Vector2(-MAP_HALF_SIZE, -MAP_HALF_SIZE), Vector2(MAP_HALF_SIZE, MAP_HALF_SIZE)
	)
	enemy.died.connect(_on_enemy_died)
	add_child(enemy)


func _on_enemy_died(enemy: Enemy) -> void:
	run_state.kills += 1
	var pickup := SinagPickup.new()
	pickup.value = enemy.data.xp_value
	pickup.hero = hero
	# Drop scatter uses the LOOT stream so it never disturbs the spawn sequence.
	pickup.position = enemy.global_position + Vector2(
		RngService.float_range(-6.0, 6.0, RunRng.LOOT),
		RngService.float_range(-6.0, 6.0, RunRng.LOOT)
	)
	pickup.collected.connect(_on_sinag_collected)
	add_child(pickup)


# ---------------------------------------------------------------- levelling

func _on_sinag_collected(amount: float) -> void:
	if _game_over:
		return
	run_state.add_xp(amount)
	_try_open_level_up()


func _try_open_level_up() -> void:
	if _menu_open or _game_over or run_state.pending_level_ups <= 0:
		return
	run_state.pending_level_ups -= 1
	_menu_open = true
	var options: Array[Dictionary] = LevelUpPool.build_options(
		run_state, _weapon_pool, _passive_pool, RngService.rng(), 3
	)
	get_tree().paused = true
	_level_up_menu.present(options, run_state.level - run_state.pending_level_ups)


func _on_option_chosen(option: Dictionary) -> void:
	var kind: String = option["kind"]
	var id := StringName(option["id"])
	var new_level: int = option["level"]
	match kind:
		"weapon":
			_grant_weapon(id, new_level)
		"passive":
			var passive := DataRegistry.get_data(&"upgrades", id) as UpgradeData
			if passive != null:
				run_state.set_passive(passive, new_level)
				hero.speed_mult = run_state.stat_mult(&"move_speed_mult")
				hero.pickup_mult = run_state.stat_mult(&"pickup_radius_mult")
				RunLogger.record_build_choice(&"passive", id, new_level)
		"heal":
			hero.heal(REST_HEAL)
	_menu_open = false
	get_tree().paused = false
	_try_open_level_up.call_deferred()  # several level-ups may be queued


func _grant_weapon(weapon_id: StringName, level: int) -> void:
	var weapon_data := DataRegistry.get_data(&"weapons", weapon_id) as WeaponData
	if weapon_data == null:
		return
	run_state.set_weapon_level(weapon_id, level)
	hero.set_weapon(weapon_data, level, run_state)
	RunLogger.record_build_choice(&"weapon", weapon_id, level)


func _weapons_for_pool() -> Array:
	var result: Array = []
	for id in _sorted_ids(&"weapons"):
		result.append(DataRegistry.get_data(&"weapons", id))
	return result


func _passives_for_pool() -> Array:
	var result: Array = []
	for id in _sorted_ids(&"upgrades"):
		var upgrade := DataRegistry.get_data(&"upgrades", id) as UpgradeData
		if upgrade != null and upgrade.kind == UpgradeData.Kind.PASSIVE_STAT:
			result.append(upgrade)
	return result


## Sorted so the pool order (and therefore a seeded run) never depends on file order.
func _sorted_ids(category: StringName) -> Array:
	var ids: Array = DataRegistry.ids(category)
	ids.sort()
	return ids


# ---------------------------------------------------------------- game over

func _on_hero_died() -> void:
	if _game_over:
		return
	_game_over = true
	var cause: String = str(hero.last_damage_source)
	if cause.is_empty():
		cause = "unknown"
	RunLogger.end_run(cause, run_state.level, run_state.kills)
	get_tree().paused = true
	_game_over_screen.present({
		"cause": cause,
		"time": run_time,
		"level": run_state.level,
		"kills": run_state.kills,
		"seed": RngService.current_seed,
	})


func _on_restart_requested(same_seed: bool) -> void:
	RngService.queued_seed = RngService.current_seed if same_seed else RngService.FORCE_RANDOM
	get_tree().paused = false
	get_tree().reload_current_scene()


# ---------------------------------------------------------------- setup helpers

func _build_ui() -> void:
	_hud = Hud.new()
	add_child(_hud)
	_hud.setup(self)

	_level_up_menu = LevelUpMenu.new()
	add_child(_level_up_menu)
	_level_up_menu.option_chosen.connect(_on_option_chosen)

	_game_over_screen = GameOverScreen.new()
	add_child(_game_over_screen)
	_game_over_screen.restart_requested.connect(_on_restart_requested)


## Seed priority: a queued restart request, then "--seed=N" on the command line, else random.
func _resolve_seed() -> int:
	var queued: int = RngService.queued_seed
	RngService.queued_seed = RngService.NO_QUEUED
	if queued >= 0:
		return queued
	if queued == RngService.FORCE_RANDOM:
		return -1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			var value: String = arg.trim_prefix("--seed=")
			if value.is_valid_int():
				return value.to_int()
			push_warning("[RunWorld] ignoring invalid seed '%s'" % value)
	return -1
