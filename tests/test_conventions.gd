extends RefCounted
## Every file and folder under the game folders must follow snake_case naming.
## Allows chained extensions such as "hero.gd.uid" or "sprite.png.import".

const CHECKED_ROOTS := ["scenes", "scripts", "data", "art", "audio", "tests"]


func run() -> Array:
	var failures: Array = []
	var file_regex := RegEx.create_from_string("^[a-z0-9_]+(\\.[a-z0-9]+)+$")
	var dir_regex := RegEx.create_from_string("^[a-z0-9_]+$")
	for root in CHECKED_ROOTS:
		_walk("res://%s" % root, file_regex, dir_regex, failures)
	return failures


func _walk(dir_path: String, file_regex: RegEx, dir_regex: RegEx, failures: Array) -> void:
	if not DirAccess.dir_exists_absolute(dir_path):
		return
	for file_name in DirAccess.get_files_at(dir_path):
		if file_name.begins_with("."):
			continue  # .gitkeep and friends
		if file_regex.search(file_name) == null:
			failures.append("bad file name: %s/%s (use lowercase snake_case)" % [dir_path, file_name])
	for sub_dir in DirAccess.get_directories_at(dir_path):
		if sub_dir.begins_with("."):
			continue
		if dir_regex.search(sub_dir) == null:
			failures.append("bad folder name: %s/%s (use lowercase snake_case)" % [dir_path, sub_dir])
		_walk("%s/%s" % [dir_path, sub_dir], file_regex, dir_regex, failures)
