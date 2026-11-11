class_name LevelUpMenu
extends CanvasLayer
## Pauses the game and offers three choices. Press 1/2/3, click, or use the gamepad.

signal option_chosen(option: Dictionary)

var _options: Array[Dictionary] = []
var _title: Label
var _row: HBoxContainer


func _init() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS  # keep working while the tree is paused
	visible = false


func _ready() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.65)
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 24)
	center.add_child(column)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override(&"font_size", 32)
	column.add_child(_title)

	_row = HBoxContainer.new()
	_row.add_theme_constant_override(&"separation", 16)
	column.add_child(_row)


func present(options: Array[Dictionary], new_level: int) -> void:
	_options = options
	_title.text = "Level %d! Choose one" % new_level
	for child in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	for i in options.size():
		var option: Dictionary = options[i]
		var button := Button.new()
		button.custom_minimum_size = Vector2(280, 150)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.text = "[%d] %s\n%s\n%s" % [i + 1, option["title"], option["subtitle"], option["description"]]
		button.pressed.connect(_choose.bind(i))
		_row.add_child(button)
	visible = true
	(_row.get_child(0) as Button).call_deferred("grab_focus")


func _choose(index: int) -> void:
	if not visible or index < 0 or index >= _options.size():
		return
	visible = false
	option_chosen.emit(_options[index])


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	var index := -1
	match key_event.keycode:
		KEY_1:
			index = 0
		KEY_2:
			index = 1
		KEY_3:
			index = 2
	if index >= 0:
		_choose(index)
		get_viewport().set_input_as_handled()
