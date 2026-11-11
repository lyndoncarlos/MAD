extends RefCounted
## The shipped data must be valid, and the validator must catch bad data.


func run() -> Array:
	var failures: Array = []

	# 1. Real data loads and validates.
	var result: Dictionary = DataLoader.load_all()
	for message in result["errors"]:
		failures.append("load error: %s" % message)
	var entries: Array = result["entries"]
	if entries.is_empty():
		failures.append("no data files were loaded")
	for problem in DataValidator.validate(entries):
		failures.append("data problem: %s" % problem)

	# 2. The validator must flag a hero with several things wrong.
	var bad := HeroData.new()
	bad.id = &"BadId"
	bad.display_name = ""
	bad.max_hp = 0.0
	bad.starting_weapon_id = &"does_not_exist"
	var bad_entries: Array = entries.duplicate()
	bad_entries.append({"category": &"heroes", "path": "res://data/heroes/wrong_name.tres", "resource": bad})
	var problems: Array[String] = DataValidator.validate(bad_entries)
	var expected_fragments: Array = ["snake_case", "file name", "display_name", "max_hp", "starting_weapon_id"]
	for fragment in expected_fragments:
		var found := false
		for problem in problems:
			if problem.contains(fragment):
				found = true
				break
		if not found:
			failures.append("validator did not report: %s" % fragment)

	# 3. A duplicate id in the same category must be flagged.
	var duplicate_entries: Array = entries.duplicate()
	for entry in entries:
		if entry["category"] == &"enemies":
			duplicate_entries.append({
				"category": &"enemies",
				"path": "res://data/enemies/tiyanak_copy.tres",
				"resource": entry["resource"],
			})
			break
	var duplicate_found := false
	for problem in DataValidator.validate(duplicate_entries):
		if problem.contains("duplicate id"):
			duplicate_found = true
	if not duplicate_found:
		failures.append("validator did not report a duplicate id")

	return failures
