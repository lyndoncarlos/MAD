extends SceneTree
## Headless test runner. Runs every res://tests/test_*.gd file.
##
##   godot --headless --import            (once, so class_name scripts are registered)
##   godot --headless --script res://tests/run_tests.gd
##
## Each test file extends RefCounted and has `func run() -> Array` returning a list
## of failure messages (empty = pass). Exit code is 0 on success, 1 on any failure.


func _init() -> void:
	var failed_suites := 0
	var suites := 0
	var files: PackedStringArray = DirAccess.get_files_at("res://tests")
	files.sort()
	for file_name in files:
		if not (file_name.begins_with("test_") and file_name.ends_with(".gd")):
			continue
		suites += 1
		var script: GDScript = load("res://tests/%s" % file_name)
		var suite: Object = script.new()
		var failures: Array = suite.run()
		if failures.is_empty():
			print("PASS  %s" % file_name)
		else:
			failed_suites += 1
			print("FAIL  %s" % file_name)
			for message in failures:
				print("        - %s" % str(message))
	print("")
	print("%d suites, %d failed" % [suites, failed_suites])
	quit(1 if failed_suites > 0 else 0)
