class_name InputSetup
## Registers gameplay input actions in code so the map lives in one reviewable place.
## Touch input is handled separately by TouchControls.

static func ensure() -> void:
	_add(&"move_left", [KEY_A, KEY_LEFT], JOY_AXIS_LEFT_X, -1.0)
	_add(&"move_right", [KEY_D, KEY_RIGHT], JOY_AXIS_LEFT_X, 1.0)
	_add(&"move_up", [KEY_W, KEY_UP], JOY_AXIS_LEFT_Y, -1.0)
	_add(&"move_down", [KEY_S, KEY_DOWN], JOY_AXIS_LEFT_Y, 1.0)
	_add(&"sprint", [KEY_SHIFT])
	_add_button(&"sprint", JOY_BUTTON_B)
	_add_button(&"sprint", JOY_BUTTON_X)
	_add(&"debug_hour", [KEY_BRACKETRIGHT])
	_add(&"debug_day", [KEY_BRACKETLEFT])
	_add(&"debug_weather", [KEY_BACKSLASH])
	_add(&"interact", [KEY_E, KEY_SPACE, KEY_ENTER])
	_add(&"journal", [KEY_J, KEY_TAB])
	_add(&"menu", [KEY_ESCAPE])
	_add_button(&"interact", JOY_BUTTON_A)
	_add_button(&"journal", JOY_BUTTON_Y)
	_add_button(&"menu", JOY_BUTTON_START)
	# menus: make sure a gamepad can confirm and cancel in the built-in ui actions
	_ensure_button(&"ui_accept", JOY_BUTTON_A)
	_ensure_button(&"ui_cancel", JOY_BUTTON_B)


static func _add(action: StringName, keys: Array, axis: int = -1, axis_value: float = 0.0) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, 0.25)
	for k: int in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k as Key
		InputMap.action_add_event(action, ev)
	if axis >= 0:
		var jm := InputEventJoypadMotion.new()
		jm.axis = axis as JoyAxis
		jm.axis_value = axis_value
		InputMap.action_add_event(action, jm)


static func _add_button(action: StringName, button: JoyButton) -> void:
	var jb := InputEventJoypadButton.new()
	jb.button_index = button
	InputMap.action_add_event(action, jb)


static func _ensure_button(action: StringName, button: JoyButton) -> void:
	for e in InputMap.action_get_events(action):
		var jb := e as InputEventJoypadButton
		if jb != null and jb.button_index == button:
			return
	_add_button(action, button)
