extends Node


func _ready():
	_setup_actions()


func _setup_actions():
	_add_key("move_up", KEY_W)
	_add_key("move_down", KEY_S)
	_add_key("move_left", KEY_A)
	_add_key("move_right", KEY_D)
	_add_mouse("fire", MOUSE_BUTTON_LEFT)
	_add_key("open_shop", KEY_E)
	_add_key("ability_1", KEY_2)
	_add_key("ability_1_alt", KEY_U)
	_add_key("ability_2", KEY_I)
	_add_key("ability_3", KEY_O)
	_add_key("ability_4", KEY_P)
	_add_key("pause", KEY_ESCAPE)
	_add_mouse("summon", MOUSE_BUTTON_RIGHT)
	_add_mouse("weapon_next", MOUSE_BUTTON_WHEEL_UP)
	_add_mouse("weapon_prev", MOUSE_BUTTON_WHEEL_DOWN)


func _add_key(action: String, keycode: Key):
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev = InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action, ev)


func _add_mouse(action: String, button: MouseButton):
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev = InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)
