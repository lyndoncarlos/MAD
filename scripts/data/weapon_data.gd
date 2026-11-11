class_name WeaponData
extends BaseData

enum Pattern { PROJECTILE, ORBIT, AURA, ARC, ZONE_TRAIL, THROWN }

@export var pattern: Pattern = Pattern.PROJECTILE
@export var base_damage: float = 10.0
## PROJECTILE: seconds between volleys.
## ORBIT: seconds between hits on the same enemy.
@export var cooldown: float = 1.0
## Scales orbit radius (and later, area effects).
@export var area: float = 1.0
## Projectiles per volley, or orbs for ORBIT, at level 1.
@export var projectile_count: int = 1
## +1 projectile/orb every N levels (0 = never).
@export var extra_projectile_every_levels: int = 0
## PROJECTILE: how long a shot lives, in seconds.
@export var duration: float = 1.0
@export var projectile_speed: float = 400.0
## Radius of the shot or orb used for hit detection.
@export var hit_radius: float = 10.0
## How many extra enemies a projectile passes through (0 = stops on first hit).
@export var pierce: int = 0
## PROJECTILE: only fire at enemies within this distance.
@export var target_range: float = 500.0
## ORBIT: distance from the hero (before `area`), and rotation speed.
@export var orbit_radius: float = 70.0
@export var orbit_speed_deg: float = 180.0
@export var max_level: int = 8
## Fractional damage gain per level (0.15 = +15% of base damage per level).
@export var damage_per_level: float = 0.15
## Optional status applied on hit, e.g. &"calm" for Insenso (later milestone).
@export var status_effect: StringName = &""
## Evolution recipe: this weapon at max level + this passive = evolved weapon.
@export var evolves_with_passive_id: StringName = &""
@export var evolved_weapon_id: StringName = &""
