class_name WeaponMath
extends RefCounted
## Weapon numbers as pure functions. Weapons (in game) and spawn pressure (difficulty
## scaling) both use these, so they always agree about how strong a build is.

## Chance that one orbiting orb is touching a given enemy at any moment (rough estimate).
const ORBIT_SINGLE_ORB_UPTIME := 0.35


static func damage(data: WeaponData, level: int, damage_mult: float = 1.0) -> float:
	var level_mult: float = 1.0 + data.damage_per_level * float(level - 1)
	return data.base_damage * level_mult * damage_mult


## Projectiles per volley (or orbs), including the "+1 every N levels" bonus.
static func projectile_count(data: WeaponData, level: int) -> int:
	var extra := 0
	if data.extra_projectile_every_levels > 0:
		extra = floori(float(level - 1) / float(data.extra_projectile_every_levels))
	return data.projectile_count + extra


## Rough damage per second against enemies in range. Not a simulation: it exists so
## "how strong is this build" can be compared across upgrades.
static func estimated_dps(data: WeaponData, level: int, damage_mult: float = 1.0) -> float:
	var per_second: float = damage(data, level, damage_mult) / maxf(data.cooldown, 0.05)
	var count: int = projectile_count(data, level)
	match data.pattern:
		WeaponData.Pattern.PROJECTILE:
			return per_second * float(count)
		WeaponData.Pattern.ORBIT:
			# One hit per enemy per cooldown, but more orbs means more of the time in contact.
			var uptime: float = 1.0 - pow(1.0 - ORBIT_SINGLE_ORB_UPTIME, float(count))
			return per_second * uptime
	return per_second
