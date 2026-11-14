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
