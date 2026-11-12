class_name SpawnOrder
extends RefCounted
## "Spawn this many of this enemy together" (one pack).

var enemy_id: StringName
var count: int


func _init(id: StringName = &"", pack_count: int = 1) -> void:
	enemy_id = id
	count = pack_count
