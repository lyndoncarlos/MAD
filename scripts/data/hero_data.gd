class_name HeroData
extends BaseData

enum Lineage { WARRIOR, BABAYLAN, HUNTER }

@export var lineage: Lineage = Lineage.WARRIOR
## Regional title shown in the UI, e.g. "Babaylan", "Mumbaki".
@export var regional_title: String = ""
@export var max_hp: float = 100.0
@export var move_speed: float = 180.0
@export var pickup_radius: float = 60.0
@export var starting_weapon_id: StringName = &""
## Grey-box colour used until real art exists.
@export var body_color: Color = Color.WHITE
