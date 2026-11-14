class_name RunDirector
extends RefCounted
## Rules for the shape of a 20-minute run: named phases, the win at 20:00, scheduled elites,
## the Blood Moon meter and pickup drop rolls. No nodes and no randomness of its own
## (callers pass in rolls from RngService), so it is easy to unit test.

const DURATION_SECONDS := 1200.0

## [display name, start minute]. Each phase lasts until the next one starts.
const PHASES: Array = [
	["Dusk", 0.0],
	["Night", 3.0],
	["Midnight", 8.0],
	["Pre-dawn", 14.0],
]

## Elites arrive at these minutes (one each).
const ELITE_MINUTES: Array = [4.0, 8.0, 12.0, 16.0]

## Blood Moon: kills fill the meter; when full the moon rises for a while, then the meter restarts.
const METER_PER_KILL := 0.01
const BLOOD_MOON_SECONDS := 20.0
const BLOOD_MOON_SPAWN_MULT := 1.4
const BLOOD_MOON_XP_MULT := 2.0

## Pickup drop chances per kill (rolled 0..1, lower rolls win).
const HERB_CHANCE := 0.02
const MAGNET_CHANCE := 0.006

enum Drop { NONE, HERB, MAGNET, CHEST }

## 0..1. Fills with kills, outside of a Blood Moon.
var meter: float = 0.0
var blood_moon_left: float = 0.0
var blood_moons_triggered: int = 0

var _elites_spawned: int = 0


func is_complete(run_time: float) -> bool:
	return run_time >= DURATION_SECONDS


func phase_index(run_time: float) -> int:
	var minute: float = run_time / 60.0
	var index := 0
	for i in PHASES.size():
		if minute >= float(PHASES[i][1]):
			index = i
	return index


func phase_name(run_time: float) -> String:
	return PHASES[phase_index(run_time)][0]


func is_blood_moon() -> bool:
	return blood_moon_left > 0.0


## Advance the Blood Moon timer. Returns true on the tick the moon sets.
func tick(delta: float) -> bool:
	if blood_moon_left <= 0.0:
		return false
	blood_moon_left = maxf(0.0, blood_moon_left - delta)
	return blood_moon_left <= 0.0


## Register kills. Returns true if this started a Blood Moon.
func add_kills(count: int = 1) -> bool:
	if is_blood_moon():
		return false
	meter = minf(1.0, meter + METER_PER_KILL * float(count))
	if meter >= 1.0:
		meter = 0.0
		blood_moon_left = BLOOD_MOON_SECONDS
		blood_moons_triggered += 1
		return true
	return false


func spawn_mult() -> float:
	return BLOOD_MOON_SPAWN_MULT if is_blood_moon() else 1.0


func xp_mult() -> float:
	return BLOOD_MOON_XP_MULT if is_blood_moon() else 1.0


## How many scheduled elites are due now and not yet handed out.
func take_due_elites(run_time: float) -> int:
	var due := 0
	while _elites_spawned < ELITE_MINUTES.size() and run_time >= float(ELITE_MINUTES[_elites_spawned]) * 60.0:
		_elites_spawned += 1
		due += 1
	return due


## What a dying enemy drops. `roll` is a 0..1 value from the LOOT stream.
## Elites always drop a chest; others may drop a herb or a magnet.
static func drop_for(is_elite: bool, roll: float) -> int:
	if is_elite:
		return Drop.CHEST
	if roll < MAGNET_CHANCE:
		return Drop.MAGNET
	if roll < MAGNET_CHANCE + HERB_CHANCE:
		return Drop.HERB
	return Drop.NONE
