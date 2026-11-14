extends Node2D
## Repeatable stress test: a god-mode hero with two maxed weapons holds off a constant
## horde of N enemies, and frame times and enemy-update costs are recorded.
##
##   godot --path . res://scenes/benchmark/benchmark.tscn -- --enemies=800 --seconds=20 --auto-quit
##
## Options: --enemies=N (default 500)  --seconds=S (default 20)  --auto-quit  --vsync
## Results print to the Output panel and are saved to user://benchmarks/ as JSON.
## Vsync is OFF by default so the numbers show real headroom, not the monitor refresh rate.

const HERO_SCENE: PackedScene = preload("res://scenes/heroes/hero.tscn")
const MAP_SCENE: PackedScene = preload("res://scenes/maps/test_map.tscn")
const BENCH_SEED := 12345
const WARMUP_SECONDS := 3.0
const MAX_SPAWNS_PER_FRAME := 40
const SPAWN_MIN_DISTANCE := 350.0
const SPAWN_MAX_DISTANCE := 800.0

var _target_enemies: int = 500
var _duration: float = 20.0
var _auto_quit: bool = false

var _hero: Hero
var _enemies: EnemyManager
var _enemy_data: EnemyData
var _label: Label
var _elapsed: float = 0.0
var _measured_seconds: float = 0.0
var _ticks_at_start: int = 0
var _measuring: bool = false
var _finished: bool = false
var _peak_alive: int = 0

var _frame_ms: PackedFloat32Array = PackedFloat32Array()
var _total_ms: PackedFloat32Array = PackedFloat32Array()
var _enemy_ms: PackedFloat32Array = PackedFloat32Array()
var _separation_ms: PackedFloat32Array = PackedFloat32Array()
var _release_ms: PackedFloat32Array = PackedFloat32Array()
var _grid_ms: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
	_parse_args()
	InputSetup.ensure_actions()
	RngService.start_run(BENCH_SEED)  # fixed seed: runs are comparable

	var hero_data := DataRegistry.get_data(&"heroes", &"tala") as HeroData
	var tiyanak := DataRegistry.get_data(&"enemies", &"tiyanak") as EnemyData
	var curve := DataRegistry.get_data(&"level_curves", &"level_curve_default") as LevelCurveData
	if hero_data == null or tiyanak == null or curve == null:
		push_error("[Benchmark] missing data; cannot run")
		return

	# Walk-in variant of the Tiyanak so the test is steady-state, not dominated by burrowing.
	_enemy_data = tiyanak.duplicate() as EnemyData
	_enemy_data.spawn_style = EnemyData.SpawnStyle.RING
	_enemy_data.contact_damage = 0.0

	add_child(MAP_SCENE.instantiate())
	_enemies = EnemyManager.new()
	add_child(_enemies)
	_hero = HERO_SCENE.instantiate() as Hero
	_hero.setup(hero_data)
	_hero.god_mode = true
	_hero.enemies = _enemies
	add_child(_hero)
	_enemies.setup(_hero)

	# Two maxed weapons: heavy projectile and orbit load.
	var state := RunState.new(curve)
	for weapon_id in [&"spirit_staff", &"asin"]:
		var weapon := DataRegistry.get_data(&"weapons", weapon_id) as WeaponData
		state.set_weapon(weapon, weapon.max_level)
		_hero.set_weapon(weapon, weapon.max_level, state)

	var layer := CanvasLayer.new()
	_label = Label.new()
	_label.position = Vector2(12, 8)
	layer.add_child(_label)
	add_child(layer)

	print("[Benchmark] %d enemies for %.0fs (+%.0fs warm-up), seed %d" % [_target_enemies, _duration, WARMUP_SECONDS, BENCH_SEED])


func _physics_process(_delta: float) -> void:
	if _enemies == null or _finished:
		return
	var spawned := 0
	while _enemies.alive_count() < _target_enemies and spawned < MAX_SPAWNS_PER_FRAME:
		var angle: float = RngService.float_range(0.0, TAU, RunRng.SPAWN)
		var distance: float = RngService.float_range(SPAWN_MIN_DISTANCE, SPAWN_MAX_DISTANCE, RunRng.SPAWN)
		_enemies.spawn(_enemy_data, _hero.position + SpawnPlanner.ring_offset(angle, distance))
		spawned += 1
	_peak_alive = maxi(_peak_alive, _enemies.alive_count())

	if _measuring:
		# This node ticks before the manager, so these are the previous tick's costs.
		_total_ms.append(float(_enemies.last_total_usec) / 1000.0)
		_enemy_ms.append(float(_enemies.last_enemy_usec) / 1000.0)
		_separation_ms.append(float(_enemies.last_separation_usec) / 1000.0)
		_release_ms.append(float(_enemies.last_release_usec) / 1000.0)
		_grid_ms.append(float(_enemies.last_grid_usec) / 1000.0)


func _process(delta: float) -> void:
	if _enemies == null or _finished:
		return
	_elapsed += delta
	if not _measuring and _elapsed >= WARMUP_SECONDS:
		_measuring = true
		_ticks_at_start = Engine.get_physics_frames()
	if _measuring:
		_frame_ms.append(delta * 1000.0)
		_measured_seconds += delta
	_label.text = "%s   enemies: %d / %d   FPS: %d   %.1fs" % [
		"MEASURING" if _measuring else "warming up",
		_enemies.alive_count(), _target_enemies,
		Engine.get_frames_per_second(), _elapsed,
	]
	if _measuring and _measured_seconds >= _duration:
		_finish()


func _finish() -> void:
	_finished = true
	var result: Dictionary = BenchmarkStats.summarize_frames(_frame_ms)
	var ticks_run: int = Engine.get_physics_frames() - _ticks_at_start
	result["sim_speed_ratio"] = BenchmarkStats.sim_speed_ratio(ticks_run, _measured_seconds, float(Engine.physics_ticks_per_second))
	var phases := {
		"enemy_update": _enemy_ms, "separation": _separation_ms,
		"release": _release_ms, "grid_rebuild": _grid_ms, "manager_total": _total_ms,
	}
	for phase_name in phases:
		var stats: Dictionary = BenchmarkStats.avg_max(phases[phase_name])
		result["avg_ms_%s" % phase_name] = stats["avg"]
		result["max_ms_%s" % phase_name] = stats["max"]
	result["target_enemies"] = _target_enemies
	result["peak_alive"] = _peak_alive
	result["enemy_nodes_created"] = _enemies.total_created
	result["seconds_measured"] = snappedf(_measured_seconds, 0.1)
	result["seed"] = BENCH_SEED
	result["godot"] = Engine.get_version_info()["string"]
	result["os"] = OS.get_name()
	result["renderer"] = str(ProjectSettings.get_setting("rendering/renderer/rendering_method"))
	result["vsync"] = DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED
	result["verdict"] = BenchmarkStats.verdict(result)

	DirAccess.make_dir_recursive_absolute("user://benchmarks")
	var path := "user://benchmarks/bench_%d_%d.json" % [_target_enemies, int(Time.get_unix_time_from_system())]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(result, "\t"))
		file.close()

	print("[Benchmark] ---- result ----")
	for key in result:
		print("    %s: %s" % [key, str(result[key])])
	print("[Benchmark] saved to %s" % ProjectSettings.globalize_path(path))
	_label.text = "DONE: %s   avg %.0f fps   p99 %.1f ms   sim speed %.2f" % [
		result["verdict"], result["avg_fps"], result["p99_frame_ms"], result["sim_speed_ratio"]
	]
	if _auto_quit:
		get_tree().quit()


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--enemies=") and arg.trim_prefix("--enemies=").is_valid_int():
			_target_enemies = maxi(1, arg.trim_prefix("--enemies=").to_int())
		elif arg.begins_with("--seconds=") and arg.trim_prefix("--seconds=").is_valid_float():
			_duration = maxf(1.0, arg.trim_prefix("--seconds=").to_float())
		elif arg == "--auto-quit":
			_auto_quit = true
		elif arg == "--vsync":
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
			return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
