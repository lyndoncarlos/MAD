class_name SpawnPressure
extends RefCounted
## How hard the spawner pushes, given how far the player has grown.
## Level reflects experience; DPS reflects what the chosen upgrades actually do
## (damage passives, weapon levels, extra projectiles, new weapons). Movement and
## pickup passives do not raise pressure because they do not make you kill faster.


static func compute(level: int, dps: float, baseline_dps: float, curve: SpawnCurveData) -> float:
	var level_part: float = curve.level_bonus_per_level * float(maxi(level, 1) - 1)
	var power_ratio: float = 1.0
	if baseline_dps > 0.0:
		power_ratio = maxf(dps, 0.0) / baseline_dps
	# sqrt: doubling your damage raises pressure far less than doubling it would.
	var power_part: float = curve.power_bonus * (sqrt(power_ratio) - 1.0)
	return clampf(1.0 + level_part + power_part, curve.min_pressure, curve.max_pressure)
