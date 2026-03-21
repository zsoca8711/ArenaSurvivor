extends CanvasLayer

# Story mode quest manager
# Step 0: Find the scroll (near player start, with a shovel)
# Step 1: Follow the map to find the treasure (pistol)
# Step 2: Go to a safe zone to open the shop
# Step 3: Kill 10 monsters
# Step 4: Won!

var quest_label: Label
var arrow_label: Label
var story_kills: int = 0

var scroll_pos: Vector2
var treasure_pos: Vector2
var target_safezone_pos: Vector2

var scroll_collected: bool = false
var treasure_collected: bool = false

const PICKUP_RADIUS = 50.0


func _ready():
	if not GameManager.story_mode:
		visible = false
		set_process(false)
		return
	_build_ui()
	_spawn_story_items()
	GameManager.enemy_killed_signal.connect(_on_kill)


func _build_ui():
	# Quest text (top center)
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	margin.add_theme_constant_override("margin_top", 60)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	quest_label = Label.new()
	quest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quest_label.add_theme_font_size_override("font_size", 22)
	quest_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	quest_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(quest_label)

	# Direction arrow
	arrow_label = Label.new()
	arrow_label.add_theme_font_size_override("font_size", 30)
	arrow_label.add_theme_color_override("font_color", Color(1, 0.85, 0))
	arrow_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow_label.z_index = 50
	add_child(arrow_label)

	_update_quest_text()


func _spawn_story_items():
	var player_start = Vector2(5000, 5000)

	# Scroll + shovel near player (100-200px away)
	scroll_pos = player_start + Vector2(randf_range(80, 150), randf_range(-100, 100))
	_create_item_marker(scroll_pos, Color(0.8, 0.7, 0.3), "SCROLL")

	# Treasure further away (1500-2500px)
	var angle = randf() * TAU
	treasure_pos = player_start + Vector2(cos(angle) * 2000, sin(angle) * 2000)
	treasure_pos.x = clamp(treasure_pos.x, 500, 9500)
	treasure_pos.y = clamp(treasure_pos.y, 500, 9500)

	# Find nearest safe zone for step 2
	target_safezone_pos = Vector2(3000, 3000)  # Fallback


func _create_item_marker(pos: Vector2, color: Color, text: String):
	var marker = Node2D.new()
	marker.global_position = pos
	marker.name = "Marker_" + text

	# Glowing circle
	var circle = Polygon2D.new()
	circle.color = Color(color.r, color.g, color.b, 0.4)
	var points = PackedVector2Array()
	for i in 16:
		var a = i * TAU / 16
		points.append(Vector2(cos(a) * 25, sin(a) * 25))
	circle.polygon = points
	circle.z_index = 5
	marker.add_child(circle)

	# Label
	var lbl = Label.new()
	lbl.text = text
	lbl.position = Vector2(-25, -35)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", color)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.z_index = 10
	marker.add_child(lbl)

	get_tree().current_scene.call_deferred("add_child", marker)


func _process(_delta):
	if not GameManager.story_mode:
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	match GameManager.story_step:
		0:
			_update_arrow(player, scroll_pos)
			if player.global_position.distance_to(scroll_pos) < PICKUP_RADIUS:
				_collect_scroll(player)
		1:
			_update_arrow(player, treasure_pos)
			if player.global_position.distance_to(treasure_pos) < PICKUP_RADIUS:
				_collect_treasure(player)
		2:
			_find_nearest_safezone(player)
			_update_arrow(player, target_safezone_pos)
			if player.in_safe_zone:
				_reach_safezone()
		3:
			arrow_label.visible = false
			quest_label.text = "Kill 10 monsters! (%d/10)" % story_kills
			if story_kills >= 10:
				_win_game()
		4:
			pass


func _collect_scroll(player):
	scroll_collected = true
	GameManager.story_step = 1
	# Remove scroll marker
	var marker = get_tree().current_scene.get_node_or_null("Marker_SCROLL")
	if marker:
		marker.queue_free()
	# Create treasure marker
	_create_item_marker(treasure_pos, Color(1, 0.85, 0), "TREASURE")
	_update_quest_text()
	_show_message("You found a scroll! It's a map to a hidden treasure!")


func _collect_treasure(player):
	treasure_collected = true
	GameManager.story_step = 2
	# Remove treasure marker
	var marker = get_tree().current_scene.get_node_or_null("Marker_TREASURE")
	if marker:
		marker.queue_free()
	# Give pistol (player starts with one, but this confirms it)
	_update_quest_text()
	_show_message("You found the treasure! A powerful pistol! Now find a safe zone!")


func _find_nearest_safezone(player):
	var min_dist = INF
	for zone in get_tree().get_nodes_in_group("safe_zones"):
		var dist = player.global_position.distance_to(zone.global_position)
		if dist < min_dist:
			min_dist = dist
			target_safezone_pos = zone.global_position


func _reach_safezone():
	GameManager.story_step = 3
	story_kills = 0
	_update_quest_text()
	_show_message("Safe zone reached! Now kill 10 monsters to complete the mission!")


func _on_kill():
	if GameManager.story_step == 3:
		story_kills += 1


func _win_game():
	GameManager.story_step = 4
	_update_quest_text()
	# Show win screen
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(vbox)

	var title = Label.new()
	title.text = "YOU WON!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title)

	var sub = Label.new()
	sub.text = "Mission Complete! You survived the arena!"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 24)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(sub)

	var stats = Label.new()
	stats.text = "Score: $%d | Kills: %d | Waves: %d" % [GameManager.score, GameManager.kills, WaveManager.current_wave]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 20)
	stats.add_theme_color_override("font_color", Color(1, 0.85, 0))
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(stats)

	var sp = Control.new()
	sp.custom_minimum_size = Vector2(0, 20)
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(sp)

	var btn = Button.new()
	btn.text = "Main Menu"
	btn.custom_minimum_size = Vector2(220, 50)
	btn.add_theme_font_size_override("font_size", 24)
	btn.pressed.connect(func():
		get_tree().paused = false
		GameManager.reset()
		WaveManager.reset()
		NetworkManager.disconnect_from_game()
		get_tree().change_scene_to_file("res://ui/main_menu.tscn")
	)
	vbox.add_child(btn)

	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS


func _update_quest_text():
	match GameManager.story_step:
		0: quest_label.text = "Find the ancient scroll near you!"
		1: quest_label.text = "Follow the map to the treasure!"
		2: quest_label.text = "Find a safe zone to open the shop!"
		3: quest_label.text = "Kill 10 monsters! (%d/10)" % story_kills
		4: quest_label.text = "Mission Complete!"


func _update_arrow(player, target: Vector2):
	var dir = (target - player.global_position).normalized()
	var dist = int(player.global_position.distance_to(target) / 10)
	var vp = get_viewport().get_visible_rect().size
	var center_screen = vp / 2.0
	var arrow_pos = center_screen + dir * 250.0
	arrow_pos.x = clamp(arrow_pos.x, 50, vp.x - 50)
	arrow_pos.y = clamp(arrow_pos.y, 50, vp.y - 50)
	arrow_label.position = arrow_pos
	arrow_label.rotation = dir.angle()
	arrow_label.text = "%dm >" % dist
	arrow_label.visible = true


func _show_message(text: String):
	var msg = Label.new()
	msg.text = text
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.position = Vector2(get_viewport().get_visible_rect().size.x / 2 - 200, 120)
	msg.add_theme_font_size_override("font_size", 20)
	msg.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
	msg.custom_minimum_size = Vector2(400, 0)
	msg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	msg.z_index = 100
	add_child(msg)
	var tween = msg.create_tween()
	tween.tween_property(msg, "modulate:a", 0.0, 4.0)
	tween.chain().tween_callback(msg.queue_free)
