extends Control

var center: CenterContainer
var mp_center: CenterContainer
var code_input: LineEdit
var status_label: Label


func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()


func _build_ui():
	# Background — must not block clicks
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.1, 0.06)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# ---- Main panel ----
	center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var main_panel = VBoxContainer.new()
	main_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	main_panel.add_theme_constant_override("separation", 25)
	main_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(main_panel)

	var title = Label.new()
	title.text = "ARENA SURVIVOR"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(0.9, 0.15, 0.1))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_panel.add_child(title)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_panel.add_child(spacer)

	_add_button(main_panel, "Single Player", _on_single_player)
	_add_button(main_panel, "Multiplayer", _on_multiplayer)
	_add_button(main_panel, "Quit", _on_quit)

	# ---- Multiplayer panel (HIDDEN by default) ----
	mp_center = CenterContainer.new()
	mp_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mp_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mp_center.visible = false
	add_child(mp_center)

	var mp_panel = VBoxContainer.new()
	mp_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	mp_panel.add_theme_constant_override("separation", 20)
	mp_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mp_center.add_child(mp_panel)

	var mp_title = Label.new()
	mp_title.text = "MULTIPLAYER"
	mp_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mp_title.add_theme_font_size_override("font_size", 48)
	mp_title.add_theme_color_override("font_color", Color(0.9, 0.15, 0.1))
	mp_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mp_panel.add_child(mp_title)

	var mp_spacer = Control.new()
	mp_spacer.custom_minimum_size = Vector2(0, 20)
	mp_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mp_panel.add_child(mp_spacer)

	_add_button(mp_panel, "Create Game", _on_create_game)

	var mp_spacer2 = Control.new()
	mp_spacer2.custom_minimum_size = Vector2(0, 10)
	mp_spacer2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mp_panel.add_child(mp_spacer2)

	var code_label = Label.new()
	code_label.text = "Enter Room Code:"
	code_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	code_label.add_theme_font_size_override("font_size", 22)
	code_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mp_panel.add_child(code_label)

	code_input = LineEdit.new()
	code_input.placeholder_text = "12345"
	code_input.max_length = 5
	code_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	code_input.custom_minimum_size = Vector2(200, 40)
	code_input.add_theme_font_size_override("font_size", 28)
	mp_panel.add_child(code_input)

	_add_button(mp_panel, "Join Game", _on_join_game)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_color_override("font_color", Color(1, 0.85, 0))
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mp_panel.add_child(status_label)

	var mp_spacer3 = Control.new()
	mp_spacer3.custom_minimum_size = Vector2(0, 10)
	mp_spacer3.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mp_panel.add_child(mp_spacer3)

	_add_button(mp_panel, "Back", _on_back)


func _add_button(parent: Control, text: String, callback: Callable):
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(280, 50)
	btn.add_theme_font_size_override("font_size", 24)
	btn.pressed.connect(callback)
	parent.add_child(btn)


func _on_single_player():
	get_tree().change_scene_to_file("res://main/main.tscn")


func _on_multiplayer():
	center.visible = false
	mp_center.visible = true
	status_label.text = ""


func _on_create_game():
	var code = "%05d" % (randi() % 100000)
	status_label.text = "Room code: %s\nWaiting for players... (coming soon)" % code


func _on_join_game():
	var code = code_input.text.strip_edges()
	if code.length() != 5 or not code.is_valid_int():
		status_label.text = "Enter a valid 5-digit code"
		return
	status_label.text = "Joining room %s... (coming soon)" % code


func _on_back():
	mp_center.visible = false
	center.visible = true


func _on_quit():
	get_tree().quit()
