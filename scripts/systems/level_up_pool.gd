class_name LevelUpPool
extends RefCounted
## Builds the level-up choices. Uses the seeded LEVELUP stream, so the same seed
## and the same choices always offer the same options.

const STAT_LABELS := {
	&"damage_mult": "Damage",
	&"move_speed_mult": "Move speed",
	&"pickup_radius_mult": "Pickup range",
}


## Each option is a Dictionary: kind ("weapon" | "passive" | "heal"), id, level
## (the level it will have after choosing), title, subtitle, description.
static func build_options(
	run_state: RunState,
	weapons: Array,
	passives: Array,
	rng: RunRng,
	count: int = 3,
	stream_name: StringName = RunRng.LEVELUP
) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []

	for item in weapons:
		var weapon := item as WeaponData
		if weapon == null:
			continue
		var owned: int = run_state.weapon_level(weapon.id)
		if owned > 0:
			if owned < weapon.max_level:
				candidates.append(_weapon_option(weapon, owned + 1))
		elif run_state.weapon_count() < RunState.MAX_WEAPONS:
			candidates.append(_weapon_option(weapon, 1))

	for item in passives:
		var passive := item as UpgradeData
		if passive == null:
			continue
		var owned_level: int = run_state.passive_level(passive.id)
		if owned_level > 0:
			if owned_level < passive.max_level:
				candidates.append(_passive_option(passive, owned_level + 1))
		elif run_state.passive_count() < RunState.MAX_PASSIVES:
			candidates.append(_passive_option(passive, 1))

	var result: Array[Dictionary] = []
	for option in rng.pick_unique(candidates, count, stream_name):
		result.append(option)
	if result.is_empty():
		result.append(heal_option())
	return result


static func heal_option() -> Dictionary:
	return {
		"kind": "heal",
		"id": "heal",
		"level": 0,
		"title": "Moonlight Rest",
		"subtitle": "",
		"description": "Restore 30 HP",
	}


static func _weapon_option(weapon: WeaponData, new_level: int) -> Dictionary:
	var description: String
	if new_level == 1:
		description = _pattern_text(weapon.pattern)
	else:
		description = "Damage +%d%%" % roundi(weapon.damage_per_level * 100.0)
		var every: int = weapon.extra_projectile_every_levels
		if every > 0 and (new_level - 1) % every == 0:
			description += ", +1 projectile"
	return {
		"kind": "weapon",
		"id": str(weapon.id),
		"level": new_level,
		"title": weapon.display_name,
		"subtitle": "New weapon" if new_level == 1 else "Level %d" % new_level,
		"description": description,
	}


static func _passive_option(passive: UpgradeData, new_level: int) -> Dictionary:
	var label: String = STAT_LABELS.get(passive.stat, str(passive.stat))
	return {
		"kind": "passive",
		"id": str(passive.id),
		"level": new_level,
		"title": passive.display_name,
		"subtitle": "New passive" if new_level == 1 else "Level %d" % new_level,
		"description": "%s +%d%%" % [label, roundi(passive.value_per_level * 100.0)],
	}


static func _pattern_text(pattern: WeaponData.Pattern) -> String:
	match pattern:
		WeaponData.Pattern.PROJECTILE:
			return "Fires at the nearest enemy"
		WeaponData.Pattern.ORBIT:
			return "Orbs circle you and hurt what they touch"
	return "A new way to fight"
