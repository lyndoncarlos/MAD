class_name WeaponFactory
extends RefCounted
## Maps a WeaponData pattern to the behaviour class that implements it.


static func create(data: WeaponData) -> WeaponBase:
	match data.pattern:
		WeaponData.Pattern.PROJECTILE:
			return ProjectileWeapon.new()
		WeaponData.Pattern.ORBIT:
			return OrbitWeapon.new()
	push_error("[WeaponFactory] no behaviour for pattern %d (weapon '%s')" % [data.pattern, str(data.id)])
	return null
