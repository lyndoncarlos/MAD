extends Node
## Autoload: writes one JSON summary per run to user://run_logs/.
## Used for balance analysis and for reproducing bug reports (the seed is logged).
## Keeps only the newest MAX_LOGS files.

const LOG_DIR := "user://run_logs"
const MAX_LOGS := 50
const GAME_VERSION := "0.0.1-m0"

var active: bool = false
var _run: Dictionary = {}
var _started_msec: int = 0


func start_run(hero_id: StringName, run_seed: int, chapter_id: StringName = &"chapter_01") -> void:
	_run = {
		"game_version": GAME_VERSION,
		"hero_id": str(hero_id),
		"chapter_id": str(chapter_id),
		"seed": run_seed,
		"started_unix": int(Time.get_unix_time_from_system()),
		"build": [],
	}
	_started_msec = Time.get_ticks_msec()
	active = true


## Call whenever the player gains a weapon/passive/level (M1+).
func record_build_choice(kind: StringName, item_id: StringName, level: int) -> void:
	if not active:
		return
	(_run["build"] as Array).append({
		"kind": str(kind),
		"id": str(item_id),
		"level": level,
		"at_seconds": snappedf((Time.get_ticks_msec() - _started_msec) / 1000.0, 0.1),
	})


## Ends the run and writes the log. Returns the file path ("" if nothing was written).
func end_run(cause_of_death: String, level: int = 1, kills: int = 0, extra: Dictionary = {}) -> String:
	if not active:
		return ""
	active = false
	_run["cause_of_death"] = cause_of_death
	_run["level"] = level
	_run["kills"] = kills
	_run.merge(extra, true)
	_run["time_survived_seconds"] = snappedf((Time.get_ticks_msec() - _started_msec) / 1000.0, 0.1)
	return _write_log()


func _write_log() -> String:
	DirAccess.make_dir_recursive_absolute(LOG_DIR)
	# Zero-padded timestamp first, so alphabetical order is chronological order.
	var file_name := "run_%010d_%d.json" % [_run["started_unix"], _run["seed"]]
	var path := "%s/%s" % [LOG_DIR, file_name]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("[RunLogger] could not write %s (error %d)" % [path, FileAccess.get_open_error()])
		return ""
	file.store_string(JSON.stringify(_run, "\t"))
	file.close()
	_rotate_logs()
	print("[RunLogger] wrote %s" % ProjectSettings.globalize_path(path))
	return path


func _rotate_logs() -> void:
	var files: PackedStringArray = DirAccess.get_files_at(LOG_DIR)
	files.sort()
	var excess: int = files.size() - MAX_LOGS
	for i in maxi(excess, 0):
		DirAccess.remove_absolute("%s/%s" % [LOG_DIR, files[i]])


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and active:
		end_run("quit")
