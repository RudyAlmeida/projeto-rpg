extends GutTest
## Guards the input map written by res://tools/setup_input_map.gd.

const REQUIRED_ACTIONS: Array[StringName] = [
	&"move_up", &"move_down", &"move_left", &"move_right",
	&"confirm", &"action_timing", &"cancel", &"menu",
	&"run", &"page_prev", &"page_next", &"pause",
]


func test_all_actions_exist() -> void:
	for action in REQUIRED_ACTIONS:
		assert_true(InputMap.has_action(action), "missing input action: %s" % action)


func test_every_action_has_keyboard_and_gamepad() -> void:
	for action in REQUIRED_ACTIONS:
		var events := InputMap.action_get_events(action)
		var has_key := events.any(func(e: InputEvent) -> bool: return e is InputEventKey)
		var has_pad := events.any(func(e: InputEvent) -> bool: return e is InputEventJoypadButton)
		assert_true(has_key, "%s has no keyboard binding" % action)
		assert_true(has_pad, "%s has no gamepad binding" % action)


func test_movement_supports_left_stick() -> void:
	for action in [&"move_up", &"move_down", &"move_left", &"move_right"]:
		var events := InputMap.action_get_events(action)
		assert_true(events.any(func(e: InputEvent) -> bool: return e is InputEventJoypadMotion),
			"%s has no analog stick binding" % action)


func test_confirm_press_triggers_action() -> void:
	var press := InputEventKey.new()
	press.physical_keycode = KEY_Z
	press.pressed = true
	assert_true(press.is_action_pressed(&"confirm"), "Z should confirm")
	assert_true(press.is_action_pressed(&"action_timing"), "Z should be the default timing key")
