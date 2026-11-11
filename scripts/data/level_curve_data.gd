class_name LevelCurveData
extends BaseData
## XP needed to go from level L to L+1:
##   round(base_xp + linear_per_level * (L-1) + quad_per_level * (L-1)^2)
## Placeholder numbers. Real tuning happens in M2 against the 20-minute run.

@export var base_xp: float = 5.0
@export var linear_per_level: float = 3.0
@export var quad_per_level: float = 0.2


func xp_to_next(level: int) -> float:
	var steps: float = float(maxi(level, 1) - 1)
	return maxf(1.0, roundf(base_xp + linear_per_level * steps + quad_per_level * steps * steps))
