class_name EnemyData
extends BaseData

enum SpawnStyle { RING, BURROW }

## Largest allowed radius. The spatial grid's neighbour queries rely on it.
const MAX_RADIUS := 40.0

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

@export_group("Spawn")
## RING: appears off-screen and walks in. BURROW: telegraphs from the ground close to the hero.
@export var spawn_style: SpawnStyle = SpawnStyle.RING
## BURROW: how far from the hero the mound may appear (min/max, in pixels).
@export var burrow_min_distance: float = 200.0
@export var burrow_max_distance: float = 420.0
## BURROW: seconds of warning (untargetable, harmless) before it emerges.
@export var burrow_telegraph_seconds: float = 0.9

@export_group("Emerge burst")
## Speed multiplier at the moment of emerging; eases back down to normal speed.
## 1.0 or less turns the burst off.
@export var emerge_speed_mult: float = 1.0
@export var emerge_burst_seconds: float = 0.0

@export_group("Charge abilities")
## While chasing, the enemy periodically winds up and then SPRINTS in a straight line or LEAPS
## onto where the hero stood. Both are telegraphed. 0 for the max interval turns abilities off.
@export var ability_interval_min: float = 0.0
@export var ability_interval_max: float = 0.0
## Chance (0..1) that an ability is a leap rather than a sprint.
@export var leap_chance: float = 0.4
@export var sprint_windup_seconds: float = 0.6
@export var sprint_seconds: float = 0.9
@export var sprint_speed_mult: float = 3.2
@export var leap_windup_seconds: float = 0.5
@export var leap_seconds: float = 0.55
## How high the leap looks (pixels). Visual only.
@export var leap_height: float = 46.0
