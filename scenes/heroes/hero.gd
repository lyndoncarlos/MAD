class_name Hero
extends CharacterBody2D
## Generic hero. Identity (speed, HP, colour, starting weapon) comes from HeroData,
## so Tala, Datu Kidlat and Hassan all use this one scene.

signal damaged(amount: float)
signal died

const DRAW_RADIUS := 14.0
const INVULNERABLE_SECONDS := 0.5

var data: HeroData
var current_hp: float = 100.0
## Multipliers from passives, set by the run controller.
var speed_mult: float = 1.0
var pickup_mult: float = 1.0
## Id of whatever dealt the last hit (shown on the game-over screen and logged).
var last_damage_source: StringName = &""
## Set by whoever creates the hero, so weapons can find enemies.
var enemies: EnemyManager
## Benchmarks and debugging: take no damage.
var god_mode: bool = false

var _facing: Vector2 = Vector2.RIGHT
var _invulnerable_left: float = 0.0
var _dead: bool = false
var _weapons: Dictionary = {}  # weapon id -> WeaponBase


## Call before adding the hero to the tree.
func setup(hero_data: HeroData) -> void:
	data = hero_data
	current_hp = data.max_hp
	queue_redraw()


func _ready() -> void:
	# Top-down game: no gravity or floor.
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING


func is_dead() -> bool:
	return _dead


func pickup_radius() -> float:
	var base: float = data.pickup_radius if data != null else 60.0
	return base * pickup_mult


func take_damage(amount: float, source_id: StringName = &"") -> void:
	if god_mode or _dead or _invulnerable_left > 0.0 or amount <= 0.0:
		return
	current_hp = maxf(0.0, current_hp - amount)
	last_damage_source = source_id
	_invulnerable_left = INVULNERABLE_SECONDS
	damaged.emit(amount)
	DamageNumber.spawn(get_parent(), global_position, amount, Color(1.0, 0.45, 0.45))
	if current_hp <= 0.0:
		_dead = true
		died.emit()


func heal(amount: float) -> void:
	if _dead:
		return
	current_hp = minf(data.max_hp, current_hp + amount)


## Adds a weapon, or sets its level if the hero already has it.
func set_weapon(weapon_data: WeaponData, level: int, state: RunState) -> void:
	if _weapons.has(weapon_data.id):
		(_weapons[weapon_data.id] as WeaponBase).set_level(level)
		return
	var weapon := WeaponFactory.create(weapon_data)
	if weapon == null:
		return
	weapon.setup(weapon_data, self, state)
	weapon.set_level(level)
	add_child(weapon)
	_weapons[weapon_data.id] = weapon


func _physics_process(delta: float) -> void:
	if _dead:
		velocity = Vector2.ZERO
		return
	var input_dir: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var speed: float = (data.move_speed if data != null else 180.0) * speed_mult
	velocity = input_dir * speed
	if input_dir != Vector2.ZERO:
		_facing = input_dir.normalized()
		queue_redraw()
	move_and_slide()

	if _invulnerable_left > 0.0:
		_invulnerable_left -= delta
	modulate.a = 0.45 if _invulnerable_left > 0.0 else 1.0


func _draw() -> void:
	var body_color: Color = data.body_color if data != null else Color.WHITE
	draw_circle(Vector2.ZERO, DRAW_RADIUS, body_color)
	draw_line(Vector2.ZERO, _facing * DRAW_RADIUS * 1.6, Color.BLACK, 3.0)
