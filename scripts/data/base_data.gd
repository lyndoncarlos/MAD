class_name BaseData
extends Resource
## Base for every data-driven game object (hero, weapon, enemy, upgrade, curve).
##
## Rules (enforced by DataValidator):
##   - `id` is snake_case ASCII and equals the file name without extension.
##   - `id` never changes once referenced by saves, logs or evolution recipes.
##   - `display_name` carries the proper spelling (e.g. "Sulô"); the id does not.

@export var id: StringName = &""
@export var display_name: String = ""
@export var schema_version: int = 1
## Which people/tradition this comes from, for cultural credit and the Aklat ng
## mga Nilalang. Example: "Ifugao", "Ilocano epic", "Tagalog".
@export var source: String = ""
@export_multiline var notes: String = ""
