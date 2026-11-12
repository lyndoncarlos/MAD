class_name EnemyMotion
extends RefCounted
## Movement rules that need no nodes, so they can be unit tested.


## Speed during the emerge burst: starts at base * burst_mult and eases down to base.
## t is seconds since the burst started. Outside the burst, or with burst turned off,
## the result is just base_speed.
static func burst_speed(t: float, base_speed: float, burst_mult: float, burst_seconds: float) -> float:
	if burst_seconds <= 0.0 or burst_mult <= 1.0:
		return base_speed
	var progress: float = clampf(t / burst_seconds, 0.0, 1.0)
	var eased: float = 1.0 - progress * progress  # 1.0 at the start, 0.0 at the end
	return base_speed * (1.0 + (burst_mult - 1.0) * eased)
