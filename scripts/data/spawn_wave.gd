class_name SpawnWave
extends Resource
## One row of a spawn curve: "between these minutes, spawn this enemy at this rate".

@export var start_minute: float = 0.0
@export var end_minute: float = 1.0
@export var enemy_id: StringName = &""
@export var spawns_per_second: float = 1.0
## Cap on how many of this enemy may be alive at once.
@export var max_alive: int = 50
