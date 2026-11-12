class_name SpawnCurveData
extends BaseData
## A chapter's spawn plan plus how strongly it reacts to the player's growth.
##
## pressure = 1 + level_bonus_per_level * (level - 1)
##              + power_bonus * (sqrt(player_dps / starting_dps) - 1)
## then clamped to [min_pressure, max_pressure]. Pressure multiplies BOTH the spawn rate
## and the alive cap of every wave. Pack size grows with time only.

@export var duration_minutes: float = 20.0
@export var waves: Array[SpawnWave] = []
@export_group("Pressure")
## Extra pressure per player level above 1 (0.02 = +2% per level).
@export var level_bonus_per_level: float = 0.02
## How much your build's damage output raises pressure. 0 turns it off.
@export var power_bonus: float = 0.15
@export var min_pressure: float = 1.0
@export var max_pressure: float = 2.0
