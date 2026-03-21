extends CanvasLayer

var health_bar: ProgressBar
var health_label: Label
var money_label: Label
var wave_label: Label
var timer_label: Label
var kills_label: Label
var weapon_label: Label
var center_message: Label
var _center_msg_tween: Tween


func _ready():
	_build_ui()
	_connect_signals()
	center_message.visible = false


func _build_ui():
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 10)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 30)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(hbox)

	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(200, 25)
	health_bar.value = 100
	health_bar.show_percentage = false
	var fg = StyleBoxFlat.new()
	fg.bg_color = Color(0.8, 0.1, 0.1)
	health_bar.add_theme_stylebox_override("fill", fg)
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.3, 0.1, 0.1)
	health_bar.add_theme_stylebox_override("background", bg)
	hbox.add_child(health_bar)

	health_label = _make_label("HP: 100/100")
	hbox.add_child(health_label)

	money_label = _make_label("$0", Color(1, 0.85, 0))
	hbox.add_child(money_label)

	wave_label = _make_label("Wave 0")
	hbox.add_child(wave_label)

	timer_label = _make_label("Time: 0:00")
	hbox.add_child(timer_label)

	kills_label = _make_label("Kills: 0")
	hbox.add_child(kills_label)

	# Bottom-left weapon info
	var bottom_margin = MarginContainer.new()
	bottom_margin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	bottom_margin.add_theme_constant_override("margin_left", 20)
	bottom_margin.add_theme_constant_override("margin_bottom", 15)
	bottom_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom_margin)

	weapon_label = Label.new()
	weapon_label.text = "Pistol | INF"
	weapon_label.add_theme_font_size_override("font_size", 24)
	weapon_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	weapon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_margin.add_child(weapon_label)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	center_message = Label.new()
	center_message.add_theme_font_size_override("font_size", 48)
	center_message.add_theme_color_override("font_color", Color(1, 1, 0))
	center.add_child(center_message)


func _make_label(text: String, color: Color = Color.WHITE) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", color)
	return label


func _connect_signals():
	GameManager.money_changed.connect(_on_money_changed)
	GameManager.health_changed.connect(_on_health_changed)
	WaveManager.wave_started.connect(_on_wave_started)
	WaveManager.wave_completed.connect(_on_wave_completed)
	WaveManager.buy_phase_started.connect(_on_buy_phase_started)


func _process(_delta):
	if WaveManager.wave_active:
		var t = WaveManager.get_wave_time_remaining()
		timer_label.text = "Time: %d:%02d" % [int(t) / 60, int(t) % 60]
	elif WaveManager.buy_phase_active:
		var t = WaveManager.get_buy_time_remaining()
		timer_label.text = "Shop: %d" % ceili(t)
	kills_label.text = "Kills: %d" % GameManager.kills
	# Weapon info
	var player = get_tree().get_first_node_in_group("player")
	if player:
		weapon_label.text = "%s | %s" % [player.get_weapon_name(), player.get_ammo_text()]


func _on_money_changed(amount: int):
	money_label.text = "$%d" % amount


func _on_health_changed(hp: float, max_hp: float):
	health_bar.value = (hp / max_hp) * 100.0
	health_label.text = "HP: %d/%d" % [int(hp), int(max_hp)]


func _on_wave_started(wave_number: int):
	wave_label.text = "Wave %d" % wave_number
	_show_center_message("Wave %d" % wave_number, 2.0)


func _on_wave_completed(wave_number: int):
	_show_center_message("Wave %d Cleared!" % wave_number, 2.0)


func _on_buy_phase_started(_duration: float):
	_show_center_message("Buy Phase", 3.0)


func _show_center_message(text: String, duration: float):
	if _center_msg_tween and _center_msg_tween.is_valid():
		_center_msg_tween.kill()
	center_message.text = text
	center_message.visible = true
	_center_msg_tween = create_tween()
	_center_msg_tween.tween_callback(func(): center_message.visible = false).set_delay(duration)
