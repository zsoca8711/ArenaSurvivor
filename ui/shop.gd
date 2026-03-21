extends CanvasLayer

var is_open: bool = false
var money_label: Label
var item_container: VBoxContainer

var upgrades = [
	{"id": "damage", "name": "Pistol Damage +5", "price": 200},
	{"id": "fire_rate", "name": "Fire Rate Up", "price": 300},
	{"id": "max_hp", "name": "Max HP +25", "price": 250},
	{"id": "speed", "name": "Speed +30", "price": 200},
	{"id": "heal", "name": "Full Heal", "price": 150},
]


func _ready():
	_build_ui()
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func _build_ui():
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel = VBoxContainer.new()
	panel.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_theme_constant_override("separation", 15)
	center.add_child(panel)

	var title = Label.new()
	title.text = "SHOP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0))
	panel.add_child(title)

	money_label = Label.new()
	money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	money_label.add_theme_font_size_override("font_size", 28)
	money_label.add_theme_color_override("font_color", Color(1, 0.85, 0))
	panel.add_child(money_label)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	panel.add_child(spacer)

	item_container = VBoxContainer.new()
	item_container.add_theme_constant_override("separation", 8)
	panel.add_child(item_container)

	for upgrade in upgrades:
		_add_upgrade_row(upgrade)

	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 15)
	panel.add_child(spacer2)

	var close_btn = Button.new()
	close_btn.text = "Close Shop (E)"
	close_btn.custom_minimum_size = Vector2(250, 45)
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(close)
	panel.add_child(close_btn)


func _add_upgrade_row(upgrade: Dictionary):
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	item_container.add_child(hbox)

	var name_label = Label.new()
	name_label.text = upgrade["name"]
	name_label.custom_minimum_size = Vector2(250, 0)
	name_label.add_theme_font_size_override("font_size", 22)
	hbox.add_child(name_label)

	var price_label = Label.new()
	price_label.text = "$%d" % upgrade["price"]
	price_label.custom_minimum_size = Vector2(80, 0)
	price_label.add_theme_font_size_override("font_size", 22)
	price_label.add_theme_color_override("font_color", Color(1, 0.85, 0))
	hbox.add_child(price_label)

	var buy_btn = Button.new()
	buy_btn.text = "BUY"
	buy_btn.custom_minimum_size = Vector2(80, 40)
	buy_btn.add_theme_font_size_override("font_size", 18)
	buy_btn.pressed.connect(_on_buy.bind(upgrade["id"], upgrade["price"]))
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


func _on_buy(upgrade_id: String, price: int):
	if not GameManager.spend_money(price):
		return
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	_apply_upgrade(upgrade_id, player)
	_update_money()


func _apply_upgrade(upgrade_id: String, player):
	match upgrade_id:
		"damage":
			player.damage_bonus += 5.0
		"fire_rate":
			player.fire_rate = max(0.05, player.fire_rate - 0.03)
		"max_hp":
			player.max_hp += 25.0
			player.hp = min(player.hp + 25.0, player.max_hp)
			GameManager.health_changed.emit(player.hp, player.max_hp)
		"speed":
			player.speed += 30.0
		"heal":
			player.hp = player.max_hp
			GameManager.health_changed.emit(player.hp, player.max_hp)
