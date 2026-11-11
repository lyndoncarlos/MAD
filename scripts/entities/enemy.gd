class_name Enemy
extends Node2D
## Grey-box enemy: walks straight at the hero and hurts on contact.
## Created with Enemy.new() and configured by EnemyData; no scene needed yet.
## (M2 replaces per-node logic with pooling and separation for large hordes.)

signal died(enemy: Enemy)

var data: EnemyData
var hero: Hero
var hp: float = 1.0
var is_dying: bool = false
var _flash_left: float = 0.0


func setup(enemy_data: EnemyData, target: Hero) -> void:
	data = enemy_data
	hero = target
	hp = data.max_hp


func _ready() -> void:
	add_to_group(&"enemies")


func _physics_process(delta: float) -> void:
	if is_dying or hero == null or not is_instance_valid(hero):
		return
	var to_hero: Vector2 = hero.global_position - global_position
	var distance: float = to_hero.length()
	if distance > 0.01:
		global_position += to_hero / distance * data.move_speed * delta
	if distance <= data.radius + Hero.DRAW_RADIUS:
		hero.take_damage(data.contact_damage, data.id)
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			queue_redraw()


func take_damage(amount: float) -> void:
	if is_dying:
		return
	hp -= amount
	DamageNumber.spawn(get_parent(), global_position, amount)
	_flash_left = 0.08
	queue_redraw()
	if hp <= 0.0:
		is_dying = true
		died.emit(self)
		queue_free()


func _draw() -> void:
	var color: Color = Color.WHITE if _flash_left > 0.0 else data.body_color
	draw_circle(Vector2.ZERO, data.radius, color)
