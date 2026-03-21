extends CanvasLayer

var is_open: bool = false


func _ready():
	_build_ui()
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func _build_ui():
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)

	var title = Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	vbox.add_child(title)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	_add_button(vbox, "Resume", _on_resume)
	_add_button(vbox, "Main Menu", _on_main_menu)
	_add_button(vbox, "Quit", _on_quit)


func _add_button(parent: Control, text: String, callback: Callable):
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(220, 50)
	btn.add_theme_font_size_override("font_size", 24)
	btn.pressed.connect(callback)
	parent.add_child(btn)


func open():
	is_open = true
	visible = true
	get_tree().paused = true


func close():
	is_open = false
	visible = false
	get_tree().paused = false


func _on_resume():
	close()


func _on_main_menu():
	get_tree().paused = false
	GameManager.reset()
	WaveManager.reset()
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")


func _on_quit():
	get_tree().quit()
