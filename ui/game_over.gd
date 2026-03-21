extends CanvasLayer

var score_label: Label
var kills_label: Label
var waves_label: Label
var restart_button: Button


func _ready():
	_build_ui()
	visible = false
	GameManager.game_over.connect(_on_game_over)


func _build_ui():
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
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
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.9, 0.1, 0.1))
	vbox.add_child(title)

	score_label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 32)
	score_label.add_theme_color_override("font_color", Color(1, 0.85, 0))
	vbox.add_child(score_label)

	kills_label = Label.new()
	kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kills_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(kills_label)

	waves_label = Label.new()
	waves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	waves_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(waves_label)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	restart_button = Button.new()
	restart_button.text = "Play Again"
	restart_button.custom_minimum_size = Vector2(200, 50)
	restart_button.pressed.connect(_on_restart)
	vbox.add_child(restart_button)

	var menu_button = Button.new()
	menu_button.text = "Main Menu"
	menu_button.custom_minimum_size = Vector2(200, 50)
	menu_button.pressed.connect(_on_main_menu)
	vbox.add_child(menu_button)


func _on_game_over():
	score_label.text = "Score: $%d" % GameManager.score
	kills_label.text = "Kills: %d" % GameManager.kills
	waves_label.text = "Waves survived: %d" % WaveManager.current_wave
	visible = true
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS


func _on_restart():
	get_tree().paused = false
	visible = false
	GameManager.reset()
	WaveManager.reset()
	get_tree().reload_current_scene()


func _on_main_menu():
	get_tree().paused = false
	GameManager.reset()
	WaveManager.reset()
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
