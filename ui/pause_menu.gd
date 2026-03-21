extends CanvasLayer

var is_open: bool = false
var god_mode_btn: Button


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

	# Cheats section
	var cheat_spacer = Control.new()
	cheat_spacer.custom_minimum_size = Vector2(0, 20)
	cheat_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(cheat_spacer)

	var cheat_title = Label.new()
	cheat_title.text = "-- CHEATS --"
	cheat_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cheat_title.add_theme_font_size_override("font_size", 20)
	cheat_title.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	cheat_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(cheat_title)

	_add_cheat_button(vbox, "+$1,000,000", _on_cheat_money)
	god_mode_btn = _add_cheat_button(vbox, "God Mode: OFF", _on_cheat_god_mode)
	_add_cheat_button(vbox, "Skip Wave", _on_cheat_skip_wave)
	_add_cheat_button(vbox, "Summon Demogorgon", _on_cheat_demogorgon)
	_add_cheat_button(vbox, "Summon Giant Tank", _on_cheat_giant_tank)
	_add_cheat_button(vbox, "Summon Vecna", _on_cheat_vecna)
	_add_cheat_button(vbox, "Summon Mind Flayer", _on_cheat_mind_flayer)


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


func _spawn_cheat_boss(scene_path: String):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var scene = load(scene_path)
		var boss = scene.instantiate()
		boss.global_position = player.global_position + Vector2(300, 0)
		get_tree().current_scene.get_node("Enemies").call_deferred("add_child", boss)
		WaveManager.enemies_alive += 1
