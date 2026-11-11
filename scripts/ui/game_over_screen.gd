class_name GameOverScreen
extends CanvasLayer
## Shown when the hero dies. R restarts with the same seed, N starts a new run.

signal restart_requested(same_seed: bool)

var _summary: Label


func _init() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func _ready() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.0, 0.0, 0.75)
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 20)
	center.add_child(column)

	var title := Label.new()
	title.text = "The night takes you"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 36)
	column.add_child(title)

	_summary = Label.new()
	_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary.add_theme_font_size_override(&"font_size", 20)
	column.add_child(_summary)

	var same_button := Button.new()
	same_button.text = "Retry same seed  [R]"
	same_button.custom_minimum_size = Vector2(300, 48)
	same_button.pressed.connect(_request.bind(true))
	column.add_child(same_button)

	var new_button := Button.new()
	new_button.text = "New run  [N]"
	new_button.custom_minimum_size = Vector2(300, 48)
	new_button.pressed.connect(_request.bind(false))
	column.add_child(new_button)


## summary keys: cause (String), time (float seconds), level (int), kills (int), seed (int).
func present(summary: Dictionary) -> void:
	var total_seconds: int = int(summary["time"])
	_summary.text = "Felled by: %s\nSurvived %02d:%02d   Level %d   Kills %d\nSeed %d" % [
		summary["cause"], floori(total_seconds / 60.0), total_seconds % 60,
		summary["level"], summary["kills"], summary["seed"],
	]
	visible = true


func _request(same_seed: bool) -> void:
	if not visible:
		return
	visible = false
	restart_requested.emit(same_seed)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_R:
		_request(true)
		get_viewport().set_input_as_handled()
	elif key_event.keycode == KEY_N:
		_request(false)
		get_viewport().set_input_as_handled()
