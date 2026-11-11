class_name DataLoader
extends RefCounted
## Loads every .tres under res://data/<category>/ . Pure logic with no autoload
## dependency, so the headless tests can use it directly.

const DATA_ROOT := "res://data"
const CATEGORIES: Array[StringName] = [&"heroes", &"weapons", &"enemies", &"upgrades", &"spawn_curves", &"level_curves"]


## Returns { "entries": Array[Dictionary], "errors": Array[String] }.
## Each entry is { "category": StringName, "path": String, "resource": Resource }.
static func load_all(root: String = DATA_ROOT) -> Dictionary:
	var entries: Array[Dictionary] = []
	var errors: Array[String] = []
	for category in CATEGORIES:
		var dir_path := "%s/%s" % [root, str(category)]
		if not DirAccess.dir_exists_absolute(dir_path):
			errors.append("Missing data folder: %s" % dir_path)
			continue
		var files: PackedStringArray = DirAccess.get_files_at(dir_path)
		files.sort()
		for file_name in files:
			# Exported builds list resources as "name.tres.remap"; strip the suffix.
			var clean_name: String = file_name.trim_suffix(".remap")
			if not clean_name.ends_with(".tres"):
				continue
			var path := "%s/%s" % [dir_path, clean_name]
			var resource: Resource = ResourceLoader.load(path)
			if resource == null:
				errors.append("Could not load %s" % path)
				continue
			entries.append({"category": category, "path": path, "resource": resource})
	return {"entries": entries, "errors": errors}
