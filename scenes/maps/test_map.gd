extends Node2D
## Grey-box test arena: a grid and a red boundary so movement and speed are readable.

@export var half_size: int = 2048
@export var cell_size: int = 64


func _draw() -> void:
	var grid_color := Color(1.0, 1.0, 1.0, 0.07)
	var axis_color := Color(1.0, 1.0, 1.0, 0.25)
	for i in range(-half_size, half_size + 1, cell_size):
		var color: Color = axis_color if i == 0 else grid_color
		draw_line(Vector2(i, -half_size), Vector2(i, half_size), color)
		draw_line(Vector2(-half_size, i), Vector2(half_size, i), color)
	var bounds := Rect2(-half_size, -half_size, half_size * 2, half_size * 2)
	draw_rect(bounds, Color(1.0, 0.3, 0.3, 0.6), false, 3.0)
