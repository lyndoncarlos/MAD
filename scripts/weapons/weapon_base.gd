class_name WeaponBase
extends Node2D
## Base for weapon behaviours. A weapon is a child of the Hero; the data
## (WeaponData) decides numbers, the subclass decides behaviour.

var data: WeaponData
var level: int = 1
var hero: Hero
var run_state: RunState


func setup(weapon_data: WeaponData, owner_hero: Hero, state: RunState) -> void:
	data = weapon_data
	hero = owner_hero
	run_state = state
	_on_level_changed()


func set_level(new_level: int) -> void:
	level = new_level
	_on_level_changed()


## Per-hit damage: base * level scaling * passive damage multiplier.
func current_damage() -> float:
	var level_mult: float = 1.0 + data.damage_per_level * float(level - 1)
	return data.base_damage * level_mult * run_state.stat_mult(&"damage_mult")


## Projectiles per volley (or orbs), including the "+1 every N levels" bonus.
func current_projectile_count() -> int:
	var extra := 0
	if data.extra_projectile_every_levels > 0:
		extra = floori(float(level - 1) / float(data.extra_projectile_every_levels))
	return data.projectile_count + extra


## Override in subclasses to react to level changes.
func _on_level_changed() -> void:
	pass
