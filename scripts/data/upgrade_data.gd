class_name UpgradeData
extends BaseData

enum Kind { PASSIVE_STAT, WEAPON_LEVEL, EVOLUTION }

@export var kind: Kind = Kind.PASSIVE_STAT
## Which stat a passive changes, e.g. &"damage_mult", &"move_speed_mult".
@export var stat: StringName = &""
@export var value_per_level: float = 0.1
@export var max_level: int = 5
## Stats understood by RunState.stat_mult():
##   &"damage_mult", &"move_speed_mult", &"pickup_radius_mult"
