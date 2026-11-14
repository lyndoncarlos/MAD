class_name DataValidator
extends RefCounted
## Checks loaded data against the naming rules and cross-references.
## Returns a list of human-readable problems; an empty list means all good.

const ID_PATTERN := "^[a-z][a-z0-9_]*$"


static func validate(entries: Array) -> Array[String]:
	var problems: Array[String] = []
	var id_regex := RegEx.create_from_string(ID_PATTERN)

	# Pass 1: index ids per category and check each entry on its own.
	var ids: Dictionary = {}
	for category in DataLoader.CATEGORIES:
		ids[category] = {}

	for entry in entries:
		var category: StringName = entry["category"]
		var path: String = entry["path"]
		var resource: Resource = entry["resource"]

		if not (resource is BaseData):
			problems.append("%s: not a BaseData resource" % path)
			continue
		var data: BaseData = resource
		var id_text := str(data.id)

		if not _type_matches_category(category, data):
			problems.append("%s: wrong data type for folder '%s'" % [path, str(category)])
		if id_text.is_empty():
			problems.append("%s: id is empty" % path)
		elif id_regex.search(id_text) == null:
			problems.append("%s: id '%s' is not snake_case ASCII" % [path, id_text])
		if id_text != path.get_file().get_basename():
			problems.append("%s: id '%s' does not match the file name" % [path, id_text])
		if data.display_name.strip_edges().is_empty():
			problems.append("%s: display_name is empty" % path)
		if data.schema_version < 1:
			problems.append("%s: schema_version must be >= 1" % path)

		if ids.has(category):
			if (ids[category] as Dictionary).has(data.id):
				problems.append("%s: duplicate id '%s' in %s" % [path, id_text, str(category)])
			(ids[category] as Dictionary)[data.id] = true

	# Pass 2: value ranges and cross-references.
	for entry in entries:
		var path: String = entry["path"]
		var resource: Resource = entry["resource"]
		if resource is HeroData:
			_check_hero(resource, path, ids, problems)
		elif resource is WeaponData:
			_check_weapon(resource, path, ids, problems)
		elif resource is EnemyData:
			_check_enemy(resource, path, problems)
		elif resource is UpgradeData:
			_check_upgrade(resource, path, problems)
		elif resource is SpawnCurveData:
			_check_curve(resource, path, ids, problems)
		elif resource is LevelCurveData:
			_check_level_curve(resource, path, problems)
	return problems


static func _type_matches_category(category: StringName, data: BaseData) -> bool:
	match category:
		&"heroes":
			return data is HeroData
		&"weapons":
			return data is WeaponData
		&"enemies":
			return data is EnemyData
		&"upgrades":
			return data is UpgradeData
		&"spawn_curves":
			return data is SpawnCurveData
		&"level_curves":
			return data is LevelCurveData
	return false


static func _has_id(ids: Dictionary, category: StringName, id: StringName) -> bool:
	return (ids[category] as Dictionary).has(id)


static func _check_hero(hero: HeroData, path: String, ids: Dictionary, problems: Array[String]) -> void:
	if hero.max_hp <= 0.0:
		problems.append("%s: max_hp must be > 0" % path)
	if hero.move_speed <= 0.0:
		problems.append("%s: move_speed must be > 0" % path)
	if not _has_id(ids, &"weapons", hero.starting_weapon_id):
		problems.append("%s: starting_weapon_id '%s' not found in weapons" % [path, str(hero.starting_weapon_id)])


static func _check_weapon(weapon: WeaponData, path: String, ids: Dictionary, problems: Array[String]) -> void:
	if weapon.cooldown <= 0.0:
		problems.append("%s: cooldown must be > 0" % path)
	if weapon.base_damage < 0.0:
		problems.append("%s: base_damage must be >= 0" % path)
	if weapon.max_level < 1:
		problems.append("%s: max_level must be >= 1" % path)
	if weapon.projectile_count < 1:
		problems.append("%s: projectile_count must be >= 1" % path)
	if weapon.hit_radius <= 0.0:
		problems.append("%s: hit_radius must be > 0" % path)
	if weapon.extra_projectile_every_levels < 0:
		problems.append("%s: extra_projectile_every_levels must be >= 0" % path)
	if weapon.pierce < 0:
		problems.append("%s: pierce must be >= 0" % path)
	if weapon.pattern == WeaponData.Pattern.PROJECTILE:
		if weapon.projectile_speed <= 0.0:
			problems.append("%s: projectile_speed must be > 0" % path)
		if weapon.duration <= 0.0:
			problems.append("%s: duration must be > 0" % path)
		if weapon.target_range <= 0.0:
			problems.append("%s: target_range must be > 0" % path)
	if weapon.pattern == WeaponData.Pattern.ORBIT:
		if weapon.orbit_radius <= 0.0:
			problems.append("%s: orbit_radius must be > 0" % path)
		if weapon.area <= 0.0:
			problems.append("%s: area must be > 0" % path)
	if weapon.evolves_with_passive_id != &"" and not _has_id(ids, &"upgrades", weapon.evolves_with_passive_id):
		problems.append("%s: evolves_with_passive_id '%s' not found in upgrades" % [path, str(weapon.evolves_with_passive_id)])
	if weapon.evolved_weapon_id != &"" and not _has_id(ids, &"weapons", weapon.evolved_weapon_id):
		problems.append("%s: evolved_weapon_id '%s' not found in weapons" % [path, str(weapon.evolved_weapon_id)])


static func _check_enemy(enemy: EnemyData, path: String, problems: Array[String]) -> void:
	if enemy.max_hp <= 0.0:
		problems.append("%s: max_hp must be > 0" % path)
	if enemy.move_speed < 0.0:
		problems.append("%s: move_speed must be >= 0" % path)
	if enemy.contact_damage < 0.0:
		problems.append("%s: contact_damage must be >= 0" % path)
	if enemy.radius <= 0.0 or enemy.radius > EnemyData.MAX_RADIUS:
		problems.append("%s: radius must be > 0 and <= %s" % [path, EnemyData.MAX_RADIUS])
	if enemy.xp_value < 0.0:
		problems.append("%s: xp_value must be >= 0" % path)
	if enemy.spawn_style == EnemyData.SpawnStyle.BURROW:
		if enemy.burrow_min_distance <= 0.0:
			problems.append("%s: burrow_min_distance must be > 0" % path)
		if enemy.burrow_max_distance < enemy.burrow_min_distance:
			problems.append("%s: burrow_max_distance must be >= burrow_min_distance" % path)
		if enemy.burrow_telegraph_seconds < 0.0:
			problems.append("%s: burrow_telegraph_seconds must be >= 0" % path)
	if enemy.emerge_burst_seconds < 0.0:
		problems.append("%s: emerge_burst_seconds must be >= 0" % path)
	if enemy.emerge_speed_mult < 0.0:
		problems.append("%s: emerge_speed_mult must be >= 0" % path)


static func _check_upgrade(upgrade: UpgradeData, path: String, problems: Array[String]) -> void:
	if upgrade.max_level < 1:
		problems.append("%s: max_level must be >= 1" % path)
	if upgrade.kind == UpgradeData.Kind.PASSIVE_STAT and upgrade.stat == &"":
		problems.append("%s: a passive needs a stat" % path)


static func _check_curve(curve: SpawnCurveData, path: String, ids: Dictionary, problems: Array[String]) -> void:
	if curve.duration_minutes <= 0.0:
		problems.append("%s: duration_minutes must be > 0" % path)
	if curve.level_bonus_per_level < 0.0:
		problems.append("%s: level_bonus_per_level must be >= 0" % path)
	if curve.power_bonus < 0.0:
		problems.append("%s: power_bonus must be >= 0" % path)
	if curve.min_pressure <= 0.0:
		problems.append("%s: min_pressure must be > 0" % path)
	if curve.max_pressure < curve.min_pressure:
		problems.append("%s: max_pressure must be >= min_pressure" % path)
	if curve.waves.is_empty():
		problems.append("%s: spawn curve has no waves" % path)
	for i in curve.waves.size():
		var wave: SpawnWave = curve.waves[i]
		if wave == null:
			problems.append("%s: wave %d is empty" % [path, i])
			continue
		if wave.end_minute <= wave.start_minute:
			problems.append("%s: wave %d end_minute must be after start_minute" % [path, i])
		if wave.end_minute > curve.duration_minutes:
			problems.append("%s: wave %d ends after the curve duration" % [path, i])
		if wave.spawns_per_second <= 0.0:
			problems.append("%s: wave %d spawns_per_second must be > 0" % [path, i])
		if wave.max_alive < 1:
			problems.append("%s: wave %d max_alive must be >= 1" % [path, i])
		if wave.end_spawns_per_second != -1.0 and wave.end_spawns_per_second <= 0.0:
			problems.append("%s: wave %d end_spawns_per_second must be > 0 (or -1 for 'same')" % [path, i])
		if wave.end_max_alive != -1 and wave.end_max_alive < 1:
			problems.append("%s: wave %d end_max_alive must be >= 1 (or -1 for 'same')" % [path, i])
		if wave.pack_size < 1:
			problems.append("%s: wave %d pack_size must be >= 1" % [path, i])
		if wave.end_pack_size != -1 and wave.end_pack_size < 1:
			problems.append("%s: wave %d end_pack_size must be >= 1 (or -1 for 'same')" % [path, i])
		if not _has_id(ids, &"enemies", wave.enemy_id):
			problems.append("%s: wave %d enemy_id '%s' not found in enemies" % [path, i, str(wave.enemy_id)])


static func _check_level_curve(curve: LevelCurveData, path: String, problems: Array[String]) -> void:
	if curve.base_xp <= 0.0:
		problems.append("%s: base_xp must be > 0" % path)
	if curve.linear_per_level < 0.0:
		problems.append("%s: linear_per_level must be >= 0" % path)
	if curve.quad_per_level < 0.0:
		problems.append("%s: quad_per_level must be >= 0" % path)
