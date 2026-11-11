class_name InputSetup
extends RefCounted
## Registers input actions in code so the project file stays small and
## diff-friendly. Safe to call more than once.

const MOVE_ACTIONS := {
	&"move_left": [KEY_A, KEY_LEFT],
	&"move_right": [KEY_D, KEY_RIGHT],
	&"move_up": [KEY_W, KEY_UP],
	&"move_down": [KEY_S, KEY_DOWN],
}

# Gamepad left stick: action -> [axis, direction]
const STICK_ACTIONS := {
	&"move_left": [JOY_AXIS_LEFT_X, -1.0],
	&"move_right": [JOY_AXIS_LEFT_X, 1.0],
	&"move_up": [JOY_AXIS_LEFT_Y, -1.0],
	&"move_down": [JOY_AXIS_LEFT_Y, 1.0],
}


static func ensure_actions() -> void:
	for action in MOVE_ACTIONS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action, 0.2)
		for keycode in MOVE_ACTIONS[action]:
			var key_event := InputEventKey.new()
			key_event.physical_keycode = keycode
			InputMap.action_add_event(action, key_event)
		var stick: Array = STICK_ACTIONS[action]
		var stick_event := InputEventJoypadMotion.new()
		stick_event.axis = stick[0]
		stick_event.axis_value = stick[1]
		InputMap.action_add_event(action, stick_event)
