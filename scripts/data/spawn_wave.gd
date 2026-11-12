class_name SpawnWave
extends Resource
## One row of a spawn curve: "between these minutes, spawn this enemy".
## Rate, alive cap and pack size can ramp linearly from their start value to their
## end value across the wave. An "end" value of -1 means "same as the start value".
## A spawn EVENT creates one pack (pack_size enemies together); the rate counts events.

@export var start_minute: float = 0.0
@export var end_minute: float = 1.0
@export var enemy_id: StringName = &""
@export_group("Rate (spawn events per second)")
@export var spawns_per_second: float = 1.0
@export var end_spawns_per_second: float = -1.0
@export_group("Alive cap")
@export var max_alive: int = 50
@export var end_max_alive: int = -1
@export_group("Pack size")
@export var pack_size: int = 1
@export var end_pack_size: int = -1


## 0.0 at the start of the wave, 1.0 at the end.
func progress_at(minute: float) -> float:
	var span: float = end_minute - start_minute
	if span <= 0.0:
		return 0.0
	return clampf((minute - start_minute) / span, 0.0, 1.0)


func rate_at(progress: float) -> float:
	var end_value: float = spawns_per_second if end_spawns_per_second < 0.0 else end_spawns_per_second
	return lerpf(spawns_per_second, end_value, progress)


func cap_at(progress: float) -> int:
	var end_value: int = max_alive if end_max_alive < 0 else end_max_alive
	return roundi(lerpf(float(max_alive), float(end_value), progress))


func pack_at(progress: float) -> int:
	var end_value: int = pack_size if end_pack_size < 0 else end_pack_size
	return maxi(1, roundi(lerpf(float(pack_size), float(end_value), progress)))
