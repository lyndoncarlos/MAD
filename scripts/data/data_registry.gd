extends Node
## Autoload: loads all game data at startup and serves it by category + id.
##   var hero := DataRegistry.get_data(&"heroes", &"tala") as HeroData

var entries: Array[Dictionary] = []
var load_errors: Array[String] = []
var validation_problems: Array[String] = []

var _index: Dictionary = {}


func _ready() -> void:
	reload()
	for message in load_errors:
		push_error("[DataRegistry] %s" % message)
	for message in validation_problems:
		push_error("[DataRegistry] %s" % message)
	print("[DataRegistry] loaded %d data files, %d problems" % [entries.size(), load_errors.size() + validation_problems.size()])


func reload() -> void:
	var result: Dictionary = DataLoader.load_all()
	entries.assign(result["entries"])
	load_errors.assign(result["errors"])
	validation_problems.assign(DataValidator.validate(entries))

	_index.clear()
	for entry in entries:
		var category: StringName = entry["category"]
		var data := entry["resource"] as BaseData
		if data == null:
			continue
		if not _index.has(category):
			_index[category] = {}
		(_index[category] as Dictionary)[data.id] = data


func has_data(category: StringName, id: StringName) -> bool:
	return _index.has(category) and (_index[category] as Dictionary).has(id)


## Returns null (and logs an error) if the id does not exist.
func get_data(category: StringName, id: StringName) -> BaseData:
	if not has_data(category, id):
		push_error("[DataRegistry] unknown %s id '%s'" % [str(category), str(id)])
		return null
	return (_index[category] as Dictionary)[id]


func ids(category: StringName) -> Array:
	if not _index.has(category):
		return []
	return (_index[category] as Dictionary).keys()
