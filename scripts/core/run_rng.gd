class_name RunRng
extends RefCounted
## Seeded random number streams for one run.
##
## One master seed fans out into independent named streams (spawn, loot, ...).
## Because each stream has its own state, rolling loot never changes the spawn
## sequence. That keeps runs reproducible and balance comparisons fair.
## All gameplay randomness must go through this class (via RngService).

const SPAWN := &"spawn"
const LOOT := &"loot"
const LEVELUP := &"levelup"
const COMBAT := &"combat"
const MISC := &"misc"

var master_seed: int = 0
var _streams: Dictionary = {}


func start(new_seed: int) -> void:
	master_seed = new_seed
	_streams.clear()


## Stable 32-bit FNV-1a hash of "<master>:<stream>". Deliberately not Godot's
## hash(), so the value cannot change between engine versions.
static func derive_seed(master: int, stream_name: StringName) -> int:
	var h: int = 2166136261
	var bytes: PackedByteArray = ("%d:%s" % [master, str(stream_name)]).to_utf8_buffer()
	for b in bytes:
		h = ((h ^ b) * 16777619) & 0xFFFFFFFF
	return h


## For creating a fresh seed only. Never use this for gameplay rolls.
static func random_seed() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0) & 0x7FFFFFFF


func _stream(stream_name: StringName) -> RandomNumberGenerator:
	if not _streams.has(stream_name):
		var rng := RandomNumberGenerator.new()
		rng.seed = derive_seed(master_seed, stream_name)
		_streams[stream_name] = rng
	return _streams[stream_name]


func next_float(stream_name: StringName = MISC) -> float:
	return _stream(stream_name).randf()


func float_range(low: float, high: float, stream_name: StringName = MISC) -> float:
	return _stream(stream_name).randf_range(low, high)


func int_range(low: int, high: int, stream_name: StringName = MISC) -> int:
	return _stream(stream_name).randi_range(low, high)


## True with probability p (0.0 to 1.0).
func chance(p: float, stream_name: StringName = MISC) -> bool:
	return _stream(stream_name).randf() < p


func pick(items: Array, stream_name: StringName = MISC) -> Variant:
	if items.is_empty():
		return null
	return items[_stream(stream_name).randi_range(0, items.size() - 1)]


## Returns up to `count` distinct items (partial Fisher-Yates). Does not modify `items`.
func pick_unique(items: Array, count: int, stream_name: StringName = MISC) -> Array:
	var pool: Array = items.duplicate()
	var result: Array = []
	var rng := _stream(stream_name)
	var n: int = mini(count, pool.size())
	for i in n:
		var j: int = rng.randi_range(i, pool.size() - 1)
		var tmp: Variant = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
		result.append(pool[i])
	return result
