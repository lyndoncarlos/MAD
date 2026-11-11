extends Node
## Autoload: the single entry point for gameplay randomness.
## Do not call randf()/randi()/randomize() anywhere else in gameplay code.

signal seed_changed(new_seed: int)

const NO_QUEUED := -1
const FORCE_RANDOM := -2

## Set before reloading the scene to control the next run's seed:
## a seed >= 0 reuses it, FORCE_RANDOM picks a fresh one, NO_QUEUED means "no request".
var queued_seed: int = NO_QUEUED

var _rng := RunRng.new()

var current_seed: int:
	get:
		return _rng.master_seed


## Starts a run. Pass a negative seed to get a fresh one. Returns the seed used.
func start_run(run_seed: int = -1) -> int:
	if run_seed < 0:
		run_seed = RunRng.random_seed()
	_rng.start(run_seed)
	print("[RngService] run seed: %d" % run_seed)
	seed_changed.emit(run_seed)
	return run_seed


## The underlying RunRng, for systems that take one as a parameter (e.g. LevelUpPool).
func rng() -> RunRng:
	return _rng


func next_float(stream_name: StringName = RunRng.MISC) -> float:
	return _rng.next_float(stream_name)


func float_range(low: float, high: float, stream_name: StringName = RunRng.MISC) -> float:
	return _rng.float_range(low, high, stream_name)


func int_range(low: int, high: int, stream_name: StringName = RunRng.MISC) -> int:
	return _rng.int_range(low, high, stream_name)


func chance(p: float, stream_name: StringName = RunRng.MISC) -> bool:
	return _rng.chance(p, stream_name)


func pick(items: Array, stream_name: StringName = RunRng.MISC) -> Variant:
	return _rng.pick(items, stream_name)


func pick_unique(items: Array, count: int, stream_name: StringName = RunRng.MISC) -> Array:
	return _rng.pick_unique(items, count, stream_name)
