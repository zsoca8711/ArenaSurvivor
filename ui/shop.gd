extends CanvasLayer

var is_open: bool = false
var money_label: Label
var item_container: VBoxContainer

var weapon_items = [
	{"id": "shotgun", "name": "Shotgun", "price": 500, "ammo": 30, "type": "weapon"},
	{"id": "smg", "name": "SMG", "price": 800, "ammo": 200, "type": "weapon"},
	{"id": "rifle", "name": "Rifle", "price": 1200, "ammo": 20, "type": "weapon"},
	{"id": "rocket_launcher", "name": "Rocket Launcher", "price": 2000, "ammo": 10, "type": "weapon"},
	{"id": "flamethrower", "name": "Flamethrower", "price": 1500, "ammo": 300, "type": "weapon"},
	{"id": "minigun", "name": "Minigun", "price": 3000, "ammo": 500, "type": "weapon"},
	{"id": "radio_staff", "name": "Radio Staff (homing + summon)", "price": 4000, "ammo": 200, "type": "weapon"},
	{"id": "megacluster_cannon", "name": "Megacluster Cannon", "price": 1000000, "ammo": 0, "type": "weapon"},
]

var special_items = [
	{"id": "hire_demon", "name": "Hire Radio Demon (5s aura)", "price": 3000, "type": "special"},
	{"id": "telekinetic", "name": "Telekinetic (key: 2, 10s cd)", "price": 50000, "type": "special"},
]

var upgrade_items = [
	{"id": "ammo", "name": "Ammo Refill +50", "price": 100, "type": "upgrade"},
	{"id": "heal", "name": "Full Heal", "price": 150, "type": "upgrade"},
	{"id": "damage", "name": "Damage +5", "price": 200, "type": "upgrade"},
	{"id": "fire_rate", "name": "Fire Rate Up", "price": 300, "type": "upgrade"},
	{"id": "max_hp", "name": "Max HP +25", "price": 250, "type": "upgrade"},
	{"id": "speed", "name": "Speed +30", "price": 200, "type": "upgrade"},
]


func _ready():
	_build_ui()
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event):
	if event.is_action_pressed("open_shop"):
		if is_open:
			close()
			get_viewport().set_input_as_handled()
		elif _can_open_shop():
			open()
			if GameManager.story_mode and GameManager.story_step == 2:
				GameManager.story_step = 3
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause") and is_open:
		close()
		get_viewport().set_input_as_handled()


func _can_open_shop() -> bool:
	if get_tree().paused:
		return false
	if GameManager.story_mode:
		# Story mode: only in safe zone, and only after reaching step 2+
		var player = get_tree().get_first_node_in_group("player")
		return player and player.in_safe_zone and GameManager.story_step >= 2
	else:
		return WaveManager.buy_phase_active


func _build_ui():
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel = VBoxContainer.new()
	panel.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_theme_constant_override("separation", 10)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(panel)

	var title = Label.new()
	title.text = "SHOP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(title)

	money_label = Label.new()
	money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	money_label.add_theme_font_size_override("font_size", 24)
	money_label.add_theme_color_override("font_color", Color(1, 0.85, 0))
	money_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(money_label)

	# Weapons header
	var wh = Label.new()
	wh.text = "-- Weapons --"
	wh.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wh.add_theme_font_size_override("font_size", 18)
	wh.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	wh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(wh)

	item_container = VBoxContainer.new()
	item_container.add_theme_constant_override("separation", 4)
	item_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(item_container)

	for item in weapon_items:
		_add_item_row(item)

	# Upgrades header
	var uh = Label.new()
	uh.text = "-- Upgrades --"
	uh.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	uh.add_theme_font_size_override("font_size", 18)
	uh.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	uh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(uh)

	var upgrade_container = VBoxContainer.new()
	upgrade_container.add_theme_constant_override("separation", 4)
	upgrade_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(upgrade_container)

	for item in upgrade_items:
		_add_item_row_to(upgrade_container, item)

	# Special header
	var sh = Label.new()
	sh.text = "-- Special --"
	sh.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sh.add_theme_font_size_override("font_size", 18)
	sh.add_theme_color_override("font_color", Color(0.9, 0.3, 0.9))
	sh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(sh)

	var special_container = VBoxContainer.new()
	special_container.add_theme_constant_override("separation", 4)
	special_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(special_container)

	for item in special_items:
		_add_item_row_to(special_container, item)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(spacer)

	var close_btn = Button.new()
	close_btn.text = "Close Shop (E)"
	close_btn.custom_minimum_size = Vector2(250, 40)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect(close)
	panel.add_child(close_btn)


func _add_item_row(item: Dictionary):
	_add_item_row_to(item_container, item)


func _add_item_row_to(container: VBoxContainer, item: Dictionary):
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(hbox)

	var name_label = Label.new()
	name_label.text = item["name"]
	name_label.custom_minimum_size = Vector2(220, 0)
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(name_label)

	var price_label = Label.new()
	price_label.text = "$%d" % item["price"]
	price_label.custom_minimum_size = Vector2(70, 0)
	price_label.add_theme_font_size_override("font_size", 18)
	price_label.add_theme_color_override("font_color", Color(1, 0.85, 0))
	price_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(price_label)

	var buy_btn = Button.new()
	buy_btn.text = "BUY"
	buy_btn.custom_minimum_size = Vector2(70, 34)
	buy_btn.add_theme_font_size_override("font_size", 16)
	buy_btn.pressed.connect(_on_buy.bind(item))
	hbox.add_child(buy_btn)


func open():
	if is_open:
		return
	is_open = true
	visible = true
	_update_money()
	get_tree().paused = true


func close():
	if not is_open:
		return
	is_open = false
	visible = false
	get_tree().paused = false


func _update_money():
	money_label.text = "Money: $%d" % GameManager.money


func _on_buy(item: Dictionary):
	if not GameManager.spend_money(item["price"]):
		return
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	if item["type"] == "weapon":
		player.add_weapon(item["id"], item["ammo"])
	elif item["type"] == "special":
		_apply_special(item["id"], player)
	else:
		_apply_upgrade(item["id"], player)
	_update_money()


func _apply_upgrade(upgrade_id: String, player):
	match upgrade_id:
		"ammo":
			player.add_ammo(50)
		"heal":
			player.hp = player.max_hp
			GameManager.health_changed.emit(player.hp, player.max_hp)
		"damage":
			player.damage_bonus += 5.0
		"fire_rate":
			player.fire_rate_bonus += 0.02
		"max_hp":
			player.max_hp += 25.0
			player.hp = min(player.hp + 25.0, player.max_hp)
			GameManager.health_changed.emit(player.hp, player.max_hp)
		"speed":
			player.speed += 30.0


func _apply_special(special_id: String, player):
	match special_id:
		"hire_demon":
			# Find existing radio demon or spawn one
			var demons = get_tree().get_nodes_in_group("minions")
			for d in demons:
				if d.has_method("activate_aura"):
					d.activate_aura()
					return
			# No demon found — spawn and activate
			var demon_scene = preload("res://player/radio_demon.tscn")
			var demon = demon_scene.instantiate()
			demon.global_position = player.global_position + Vector2(50, 0)
			demon.owner_player = player
			get_tree().current_scene.call_deferred("add_child", demon)
			# Activate after adding to tree
			demon.call_deferred("activate_aura")
		"telekinetic":
			player.has_telekinetic = true
