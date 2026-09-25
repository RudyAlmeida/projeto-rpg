extends SceneTree
## Writes the game's input actions into project.godot.
## Run: godot --headless --path game -s res://tools/setup_input_map.gd
## Edit ACTIONS below and re-run instead of editing the Input Map by hand.

const DEADZONE := 0.2

# action -> { keys: [physical keycodes], buttons: [joypad buttons], axes: [[axis, direction]] }
var ACTIONS := {
	"move_up": {"keys": [KEY_W, KEY_UP], "buttons": [JOY_BUTTON_DPAD_UP], "axes": [[JOY_AXIS_LEFT_Y, -1.0]]},
	"move_down": {"keys": [KEY_S, KEY_DOWN], "buttons": [JOY_BUTTON_DPAD_DOWN], "axes": [[JOY_AXIS_LEFT_Y, 1.0]]},
	"move_left": {"keys": [KEY_A, KEY_LEFT], "buttons": [JOY_BUTTON_DPAD_LEFT], "axes": [[JOY_AXIS_LEFT_X, -1.0]]},
	"move_right": {"keys": [KEY_D, KEY_RIGHT], "buttons": [JOY_BUTTON_DPAD_RIGHT], "axes": [[JOY_AXIS_LEFT_X, 1.0]]},
	# Confirm and the combat timing press share keys by default but stay separate for remapping.
	"confirm": {"keys": [KEY_Z, KEY_ENTER, KEY_SPACE], "buttons": [JOY_BUTTON_A]},
	"action_timing": {"keys": [KEY_Z, KEY_ENTER, KEY_SPACE], "buttons": [JOY_BUTTON_A]},
	"cancel": {"keys": [KEY_X, KEY_BACKSPACE], "buttons": [JOY_BUTTON_B]},
	"menu": {"keys": [KEY_C, KEY_TAB], "buttons": [JOY_BUTTON_Y]},
	"run": {"keys": [KEY_SHIFT], "buttons": [JOY_BUTTON_X]},
	"page_prev": {"keys": [KEY_Q], "buttons": [JOY_BUTTON_LEFT_SHOULDER]},
	"page_next": {"keys": [KEY_E], "buttons": [JOY_BUTTON_RIGHT_SHOULDER]},
	"pause": {"keys": [KEY_ESCAPE], "buttons": [JOY_BUTTON_START]},
}


func _init() -> void:
	for action: String in ACTIONS:
		var spec: Dictionary = ACTIONS[action]
		var events: Array[InputEvent] = []
		for keycode: int in spec.get("keys", []):
			var key := InputEventKey.new()
			key.physical_keycode = keycode
			events.append(key)
		for button: int in spec.get("buttons", []):
			var joy_button := InputEventJoypadButton.new()
			joy_button.button_index = button
			events.append(joy_button)
		for axis_spec: Array in spec.get("axes", []):
			var motion := InputEventJoypadMotion.new()
			motion.axis = axis_spec[0]
			motion.axis_value = axis_spec[1]
			events.append(motion)
		for event: InputEvent in events:
			event.device = -1  # any device, like actions created in the editor

		ProjectSettings.set_setting("input/" + action, {"deadzone": DEADZONE, "events": events})
	var err := ProjectSettings.save()
	print("input map: %d actions written (%s)" % [ACTIONS.size(), error_string(err)])
	quit(err)
