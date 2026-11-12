class_name Enemy
extends Node2D
## Grey-box enemy. Created with Enemy.new() and configured by EnemyData; no scene needed yet.
## States: BURROWED (warning, harmless, untargetable) -> BURSTING (fast lunge in a locked
## direction) -> CHASING (walks at the hero). RING-style enemies start in CHASING.
## (M2 replaces per-node logic with pooling and separation for large hordes.)

signal died(enemy: Enemy)

enum State { BURROWED, BURSTING, CHASING }

var data: EnemyData
var hero: Hero
var hp: float = 1.0
var is_dying: bool = false

var _state: State = State.CHASING
var _state_time: float = 0.0
var _burst_direction: Vector2 = Vector2.RIGHT
var _flash_left: float = 0.0


func setup(enemy_data: EnemyData, target: Hero) -> void:
	data = enemy_data
	hero = target
	hp = data.max_hp
	if data.spawn_style == EnemyData.SpawnStyle.BURROW:
		_state = State.BURROWED


func _ready() -> void:
	add_to_group(&"enemies")


## False while burrowed or dying: weapons must not aim at or hit it.
func is_targetable() -> bool:
	return not is_dying and _state != State.BURROWED


func _physics_process(delta: float) -> void:
	if is_dying or hero == null or not is_instance_valid(hero):
		return
	_state_time += delta
	match _state:
		State.BURROWED:
			queue_redraw()  # animate the warning
			if _state_time >= data.burrow_telegraph_seconds:
				_begin_burst()
			return  # harmless while burrowed
		State.BURSTING:
			_update_burst(delta)
		State.CHASING:
			_chase(delta)

	var distance: float = global_position.distance_to(hero.global_position)
	if distance <= data.radius + Hero.DRAW_RADIUS:
		hero.take_damage(data.contact_damage, data.id)
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			queue_redraw()


func take_damage(amount: float) -> void:
	if is_dying or _state == State.BURROWED:
		return
	hp -= amount
	DamageNumber.spawn(get_parent(), global_position, amount)
	_flash_left = 0.08
	queue_redraw()
	if hp <= 0.0:
		is_dying = true
		died.emit(self)
		queue_free()


func _begin_burst() -> void:
	_state_time = 0.0
	if data.emerge_burst_seconds <= 0.0 or data.emerge_speed_mult <= 1.0:
		_state = State.CHASING
	else:
		_state = State.BURSTING
		# The direction is locked at the moment of emerging, so a moving hero can dodge it.
		var to_hero: Vector2 = hero.global_position - global_position
		_burst_direction = to_hero.normalized() if to_hero.length() > 0.01 else Vector2.RIGHT
	queue_redraw()


func _update_burst(delta: float) -> void:
	var speed: float = EnemyMotion.burst_speed(
		_state_time, data.move_speed, data.emerge_speed_mult, data.emerge_burst_seconds
	)
	global_position += _burst_direction * speed * delta
	if _state_time >= data.emerge_burst_seconds:
		_state = State.CHASING
		_state_time = 0.0
		queue_redraw()


func _chase(delta: float) -> void:
	var to_hero: Vector2 = hero.global_position - global_position
	var distance: float = to_hero.length()
	if distance > 0.01:
		global_position += to_hero / distance * data.move_speed * delta


func _draw() -> void:
	if _state == State.BURROWED:
		_draw_burrow_warning()
		return
	var color: Color = Color.WHITE if _flash_left > 0.0 else data.body_color
	if _state == State.BURSTING:
		# Motion streak behind the lunge.
		draw_line(Vector2.ZERO, -_burst_direction * data.radius * 2.6, Color(1.0, 0.8, 0.8, 0.5), data.radius * 1.2)
	draw_circle(Vector2.ZERO, data.radius, color)


func _draw_burrow_warning() -> void:
	var progress: float = clampf(_state_time / maxf(data.burrow_telegraph_seconds, 0.01), 0.0, 1.0)
	var ring_radius: float = data.radius * (0.7 + 0.9 * progress)
	draw_circle(Vector2.ZERO, ring_radius, Color(0.25, 0.17, 0.1, 0.55))
	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 24, Color(0.95, 0.75, 0.4, 0.4 + 0.5 * progress), 2.0)
	for i in 4:
		var crack_angle: float = TAU * float(i) / 4.0 + progress * 0.8
		var inner: Vector2 = Vector2.RIGHT.rotated(crack_angle) * ring_radius * 0.4
		var outer: Vector2 = Vector2.RIGHT.rotated(crack_angle) * ring_radius * 1.25
		draw_line(inner, outer, Color(0.15, 0.1, 0.05, 0.85), 2.0)
