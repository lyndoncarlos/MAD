class_name EnemyData
extends BaseData

@export var max_hp: float = 10.0
@export var move_speed: float = 60.0
@export var contact_damage: float = 5.0
## Sinag (XP) dropped on death.
@export var xp_value: float = 1.0
@export var is_elite: bool = false
## True if the Balance system lets the player pacify this enemy instead of killing it.
@export var pacifiable: bool = false
@export var radius: float = 12.0
@export var body_color: Color = Color.WHITE
