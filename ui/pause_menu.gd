extends CanvasLayer

var is_open: bool = false
var god_mode_btn: Button
var cheats_unlocked: bool = false
var cheat_container: VBoxContainer
var auth_container: VBoxContainer
var auth_input: LineEdit
var auth_label: Label


func _ready():
	_build_ui()
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event):
	if event.is_action_pressed("pause"):
		if is_open:
			close()
			get_viewport().set_input_as_handled()
		elif not get_tree().paused:
			open()
			get_viewport().set_input_as_handled()


func _build_ui():
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 15)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(vbox)

	var title = Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(spacer)

	_add_button(vbox, "Resume", _on_resume)
	_add_button(vbox, "Main Menu", _on_main_menu)
	_add_button(vbox, "Quit", _on_quit)

	# Auth section (enter code to unlock cheats)
	var cheat_spacer = Control.new()
	cheat_spacer.custom_minimum_size = Vector2(0, 15)
	cheat_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(cheat_spacer)

	auth_container = VBoxContainer.new()
	auth_container.alignment = BoxContainer.ALIGNMENT_CENTER
	auth_container.add_theme_constant_override("separation", 8)
	auth_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(auth_container)

	var auth_title = Label.new()
	auth_title.text = "-- CHEATS (locked) --"
	auth_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	auth_title.add_theme_font_size_override("font_size", 18)
	auth_title.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	auth_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	auth_container.add_child(auth_title)

	auth_input = LineEdit.new()
	auth_input.placeholder_text = "Enter code..."
	auth_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	auth_input.custom_minimum_size = Vector2(180, 35)
	auth_input.add_theme_font_size_override("font_size", 20)
	auth_input.secret = true
	auth_container.add_child(auth_input)

	auth_label = Label.new()
	auth_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	auth_label.add_theme_font_size_override("font_size", 16)
	auth_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	auth_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	auth_container.add_child(auth_label)

	_add_button(auth_container, "Unlock Cheats", _on_auth_submit)

	# Cheats section (hidden until unlocked)
	cheat_container = VBoxContainer.new()
	cheat_container.alignment = BoxContainer.ALIGNMENT_CENTER
	cheat_container.add_theme_constant_override("separation", 4)
	cheat_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cheat_container.visible = false
	vbox.add_child(cheat_container)

	var cheat_title = Label.new()
	cheat_title.text = "-- CHEATS (unlocked) --"
	cheat_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cheat_title.add_theme_font_size_override("font_size", 18)
	cheat_title.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
	cheat_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cheat_container.add_child(cheat_title)

	_add_cheat_button(cheat_container, "+$1,000,000", _on_cheat_money)
	god_mode_btn = _add_cheat_button(cheat_container, "God Mode: OFF", _on_cheat_god_mode)
	_add_cheat_button(cheat_container, "Skip Wave", _on_cheat_skip_wave)
	_add_cheat_button(cheat_container, "Summon Demogorgon", _on_cheat_demogorgon)
	_add_cheat_button(cheat_container, "Summon Giant Tank", _on_cheat_giant_tank)
	_add_cheat_button(cheat_container, "Summon Vecna", _on_cheat_vecna)
	_add_cheat_button(cheat_container, "Summon Mind Flayer", _on_cheat_mind_flayer)
	_add_cheat_button(cheat_container, "Summon God", _on_cheat_god)
	_add_cheat_button(cheat_container, "Summon Satan", _on_cheat_satan)


func _add_button(parent: Control, text: String, callback: Callable):
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(220, 50)
	btn.add_theme_font_size_override("font_size", 24)
	btn.pressed.connect(callback)
	parent.add_child(btn)


func _add_cheat_button(parent: Control, text: String, callback: Callable) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(220, 40)
	btn.add_theme_font_size_override("font_size", 18)
	btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn


func open():
	is_open = true
	visible = true
	get_tree().paused = true


func close():
	is_open = false
	visible = false
	get_tree().paused = false


func lock_cheats():
	cheats_unlocked = false
	cheat_container.visible = false
	auth_container.visible = true
	auth_input.text = ""
	auth_label.text = ""


func _on_auth_submit():
	if auth_input.text.strip_edges() == "2012":
		cheats_unlocked = true
		cheat_container.visible = true
		auth_container.visible = false
	else:
		auth_label.text = "Wrong code!"
		auth_input.text = ""


func _on_resume():
	close()


func _on_main_menu():
	get_tree().paused = false
	GameManager.reset()
	WaveManager.reset()
	NetworkManager.disconnect_from_game()
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")


func _on_quit():
	get_tree().quit()


func _on_cheat_money():
	GameManager.add_money(1000000)


func _on_cheat_god_mode():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.invincible = not player.invincible
		god_mode_btn.text = "God Mode: ON" if player.invincible else "God Mode: OFF"


func _on_cheat_skip_wave():
	WaveManager.skip_wave()


func _on_cheat_demogorgon():
	_spawn_cheat_boss("res://enemies/boss_demogorgon.tscn")


func _on_cheat_giant_tank():
	_spawn_cheat_boss("res://enemies/boss_giant_tank.tscn")


func _on_cheat_vecna():
	_spawn_cheat_boss("res://enemies/boss_vecna.tscn")


func _on_cheat_mind_flayer():
	_spawn_cheat_boss("res://enemies/boss_mind_flayer.tscn")


func _on_cheat_god():
	_spawn_cheat_boss("res://enemies/boss_god.tscn")


func _on_cheat_satan():
	_spawn_cheat_boss("res://enemies/boss_satan.tscn")


func _spawn_cheat_boss(scene_path: String):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var scene = load(scene_path)
		var boss = scene.instantiate()
		boss.global_position = player.global_position + Vector2(300, 0)
		get_tree().current_scene.get_node("Enemies").call_deferred("add_child", boss)
		WaveManager.enemies_alive += 1
