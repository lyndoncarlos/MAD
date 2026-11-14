class_name DamageNumber
extends Label
## Floating damage text. Call DamageNumber.spawn(...) and forget about it.
## At most MAX_ACTIVE exist at once, so a big horde cannot flood the scene with labels.

const MAX_ACTIVE := 60


static func spawn(parent: Node, world_pos: Vector2, amount: float, color: Color = Color.WHITE) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	if parent.get_tree().get_node_count_in_group(&"damage_numbers") >= MAX_ACTIVE:
		return
	var label := DamageNumber.new()
	label.add_to_group(&"damage_numbers")
	label.text = str(maxi(1, roundi(amount)))
	label.z_index = 100
	label.add_theme_font_size_override(&"font_size", 14)
	label.add_theme_color_override(&"font_color", color)
	label.add_theme_color_override(&"font_outline_color", Color.BLACK)
	label.add_theme_constant_override(&"outline_size", 4)
	label.position = world_pos + Vector2(-8.0, -26.0)
	parent.add_child(label)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 28.0, 0.55)
	tween.tween_property(label, "modulate:a", 0.0, 0.55)
	tween.chain().tween_callback(label.queue_free)
