class_name RunState
extends RefCounted
## Everything that changes during one run: XP, level, kills, owned weapons/passives.
## Pure data and rules (no nodes), so it is easy to unit test.

signal leveled_up(new_level: int)

const MAX_WEAPONS := 6
const MAX_PASSIVES := 6

var level: int = 1
var xp: float = 0.0
var kills: int = 0
## Level-ups earned but not yet chosen (several can queue up from one big pickup).
var pending_level_ups: int = 0
var curve: LevelCurveData

var _weapons: Dictionary = {}   # id -> level
var _weapon_data: Dictionary = {}  # id -> WeaponData (only for weapons added via set_weapon)
var _passives: Dictionary = {}  # id -> { "data": UpgradeData, "level": int }


func _init(level_curve: LevelCurveData) -> void:
	curve = level_curve


func xp_needed() -> float:
	return curve.xp_to_next(level)


## Adds XP and returns how many levels were gained.
func add_xp(amount: float) -> int:
	xp += amount
	var gained := 0
	while xp >= xp_needed():
		var needed: float = xp_needed()
		xp -= needed
		level += 1
		gained += 1
		pending_level_ups += 1
		leveled_up.emit(level)
	return gained


func weapon_level(id: StringName) -> int:
	return _weapons.get(id, 0)


func set_weapon_level(id: StringName, new_level: int) -> void:
	_weapons[id] = new_level


## Like set_weapon_level, but also remembers the data so estimated_dps() can count it.
func set_weapon(data: WeaponData, new_level: int) -> void:
	_weapons[data.id] = new_level
	_weapon_data[data.id] = data


## Rough total damage per second of owned weapons (those added with set_weapon).
## Drives spawn pressure. Movement and pickup passives do not count: they do not
## make the player kill faster.
func estimated_dps() -> float:
	var total := 0.0
	var damage_mult: float = stat_mult(&"damage_mult")
	for id in _weapons:
		if _weapon_data.has(id):
			total += WeaponMath.estimated_dps(_weapon_data[id], _weapons[id], damage_mult)
	return total


func weapon_count() -> int:
	return _weapons.size()


func passive_level(id: StringName) -> int:
	if not _passives.has(id):
		return 0
	return _passives[id]["level"]


func set_passive(data: UpgradeData, new_level: int) -> void:
	_passives[data.id] = {"data": data, "level": new_level}


func passive_count() -> int:
	return _passives.size()


## Combined multiplier for a stat: 1.0 + sum of (value_per_level * level) over owned passives.
func stat_mult(stat: StringName) -> float:
	var total := 1.0
	for id in _passives:
		var entry: Dictionary = _passives[id]
		var upgrade: UpgradeData = entry["data"]
		if upgrade.stat == stat:
			total += upgrade.value_per_level * float(entry["level"])
	return total
