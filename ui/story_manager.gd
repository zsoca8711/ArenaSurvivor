extends CanvasLayer

# STORY MODE - Full quest chain
# Phase 1 (Default map):
#   0: Find scroll near start
#   1: Follow map to treasure (pistol)
#   2: Go to safe zone
#   3: Kill 10 monsters
# Phase 2 (Default map - burning village):
#   4: Go to burning village, save villagers
#   5: Kill all village monsters
# Phase 3 (Forest map):
#   6: Arrive in forest, tamed monsters in villages
#   7: Kill 100 monsters
# Phase 4 (Battlefield map):
#   8: Tamed bosses fight enemy bosses
#   9: Kill 50 enemies
# Phase 5 (Snow map - surrounded):
#   10: Break through monster ring
#   11: Collect Uranium
#   12: Collect Rocket Body
#   13: Return to village center
#   14: Build rocket → WIN

var quest_label: Label
var arrow_label: Label
var story_kills: int = 0

var scroll_pos: Vector2
var treasure_pos: Vector2
var target_pos: Vector2
var village_pos: Vector2
var uranium_pos: Vector2
var rocket_body_pos: Vector2

var has_uranium: bool = false
var has_rocket_body: bool = false

var villager_scene = preload("res://player/villager.tscn")
var minion_scene = preload("res://player/minion.tscn")

const PICKUP_RADIUS = 60.0


func _ready():
	if not GameManager.story_mode:
		visible = false
		set_process(false)
		return
	_build_ui()
	_setup_phase()
	GameManager.enemy_killed_signal.connect(_on_kill)


func _build_ui():
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

	arrow_label = Label.new()
	arrow_label.add_theme_font_size_override("font_size", 30)
	arrow_label.add_theme_color_override("font_color", Color(1, 0.85, 0))
	arrow_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow_label.z_index = 50
	add_child(arrow_label)
	arrow_label.visible = false


func _setup_phase():
	var step = GameManager.story_step
	if step <= 3:
		_setup_phase1()
	elif step <= 5:
		_setup_phase2()
	elif step <= 7:
		_setup_phase3()
	elif step <= 9:
		_setup_phase4()
	elif step <= 14:
		_setup_phase5()
	_update_quest_text()


func _setup_phase1():
	var player_start = Vector2(5000, 5000)
	scroll_pos = player_start + Vector2(randf_range(80, 150), randf_range(-100, 100))
	var angle = randf() * TAU
	treasure_pos = player_start + Vector2(cos(angle) * 2000, sin(angle) * 2000)
	treasure_pos.x = clamp(treasure_pos.x, 500, 9500)
	treasure_pos.y = clamp(treasure_pos.y, 500, 9500)
	if GameManager.story_step == 0:
		_create_marker(scroll_pos, Color(0.8, 0.7, 0.3), "SCROLL")
	elif GameManager.story_step == 1:
		_create_marker(treasure_pos, Color(1, 0.85, 0), "TREASURE")


func _setup_phase2():
	# Find a safe zone to use as the village
	call_deferred("_find_village_safezone")


func _find_village_safezone():
	var player_start = Vector2(5000, 5000)
	var best_zone = null
	var best_dist = INF
	# Find a safe zone that's not too close and not too far
	for zone in get_tree().get_nodes_in_group("safe_zones"):
		var dist = player_start.distance_to(zone.global_position)
		if dist > 500 and dist < 4000 and dist < best_dist:
			best_dist = dist
			best_zone = zone
	if best_zone:
		village_pos = best_zone.global_position
	else:
		village_pos = Vector2(3000, 3000)

	if GameManager.story_step == 4:
		_create_marker(village_pos, Color(1, 0.3, 0.1), "BURNING VILLAGE")
	elif GameManager.story_step == 5:
		_spawn_village_battle()


func _spawn_village_battle():
	# Villagers fleeing
	for i in 8:
		var v = villager_scene.instantiate()
		v.global_position = village_pos + Vector2(randf_range(-200, 200), randf_range(-200, 200))
		get_tree().current_scene.call_deferred("add_child", v)

	# Burn the safe zone — fire effects on it
	_burn_safezone(village_pos)

	# Build extra village structures around the safe zone and burn them
	_build_burning_village(village_pos)


func _burn_safezone(pos: Vector2):
	# Disable the safe zone's protection
	for zone in get_tree().get_nodes_in_group("safe_zones"):
		if zone.global_position.distance_to(pos) < 200:
			zone.protection_active = false
			zone.timer_label.text = "BURNING!"
			zone.timer_label.add_theme_color_override("font_color", Color(1, 0.2, 0.0))

	# Fire effects on the safe zone
	for i in 8:
		var fire = _create_fire(pos + Vector2(randf_range(-120, 120), randf_range(-120, 120)))
		get_tree().current_scene.call_deferred("add_child", fire)


func _build_burning_village(center: Vector2):
	var farmhouse_tex = preload("res://assets/sprites/farmhouse.png")
	var farm_hay_tex = preload("res://assets/sprites/farm_hay.png")
	var farm_corn_tex = preload("res://assets/sprites/farm_corn.png")

	# Houses around the safe zone
	var house_positions = [
		center + Vector2(-250, -200),
		center + Vector2(250, -150),
		center + Vector2(-200, 200),
		center + Vector2(280, 180),
		center + Vector2(0, -280),
		center + Vector2(-300, 0),
	]

	for pos in house_positions:
		# House
		var house = Sprite2D.new()
		house.texture = farmhouse_tex
		house.global_position = pos
		house.scale = Vector2(0.3, 0.3)
		house.z_index = 2
		get_tree().current_scene.call_deferred("add_child", house)

		# Fire on each house
		var fire = _create_fire(pos + Vector2(randf_range(-15, 15), randf_range(-15, 15)))
		get_tree().current_scene.call_deferred("add_child", fire)

	# Hay bales burning
	for i in 6:
		var hay = Sprite2D.new()
		hay.texture = farm_hay_tex
		hay.global_position = center + Vector2(randf_range(-300, 300), randf_range(-300, 300))
		hay.scale = Vector2(0.3, 0.3)
		hay.z_index = 1
		get_tree().current_scene.call_deferred("add_child", hay)
		var fire = _create_fire(hay.global_position)
		get_tree().current_scene.call_deferred("add_child", fire)

	# Corn fields burning
	for i in 10:
		var corn = Sprite2D.new()
		corn.texture = farm_corn_tex
		corn.global_position = center + Vector2(randf_range(-350, 350), randf_range(-350, 350))
		corn.scale = Vector2(0.25, 0.25)
		corn.z_index = 1
		get_tree().current_scene.call_deferred("add_child", corn)

	# Smoke columns
	for i in 4:
		var smoke = _create_smoke(center + Vector2(randf_range(-200, 200), randf_range(-200, 200)))
		get_tree().current_scene.call_deferred("add_child", smoke)


func _create_fire(pos: Vector2) -> Polygon2D:
	var fire = Polygon2D.new()
	fire.color = Color(1, randf_range(0.2, 0.5), 0.0, randf_range(0.3, 0.6))
	var pts = PackedVector2Array()
	var size = randf_range(20, 45)
	for j in 8:
		var a = j * TAU / 8
		pts.append(Vector2(cos(a) * randf_range(size * 0.5, size), sin(a) * randf_range(size * 0.5, size)))
	fire.polygon = pts
	fire.global_position = pos
	fire.z_index = 8
	return fire


func _create_smoke(pos: Vector2) -> Polygon2D:
	var smoke = Polygon2D.new()
	smoke.color = Color(0.2, 0.2, 0.2, 0.3)
	var pts = PackedVector2Array()
	for j in 10:
		var a = j * TAU / 10
		pts.append(Vector2(cos(a) * randf_range(30, 60), sin(a) * randf_range(30, 60)))
	smoke.polygon = pts
	smoke.global_position = pos
	smoke.z_index = 9
	return smoke


func _setup_phase3():
	story_kills = 0
	# Spawn tamed monster allies in forest
	call_deferred("_spawn_forest_allies")


func _spawn_forest_allies():
	for i in 6:
		var ally = minion_scene.instantiate()
		ally.global_position = Vector2(5000 + randf_range(-300, 300), 5000 + randf_range(-300, 300))
		var player = get_tree().get_first_node_in_group("player")
		if player:
			ally.owner_player = player
		ally.max_hp = 80.0
		ally.hp = 80.0
		ally.damage = 15.0
		ally.modulate = Color(0.6, 1, 0.6)
		get_tree().current_scene.call_deferred("add_child", ally)


func _setup_phase4():
	story_kills = 0
	# Spawn tamed boss allies
	call_deferred("_spawn_battlefield_allies")


func _spawn_battlefield_allies():
	for i in 3:
		var ally = minion_scene.instantiate()
		ally.global_position = Vector2(5000 + randf_range(-200, 200), 5000 + randf_range(-200, 200))
		var player = get_tree().get_first_node_in_group("player")
		if player:
			ally.owner_player = player
		ally.max_hp = 200.0
		ally.hp = 200.0
		ally.damage = 30.0
		ally.speed = 140.0
		ally.attack_range = 500.0
		ally.modulate = Color(1, 0.8, 0.3)
		ally.scale = Vector2(1.5, 1.5)
		get_tree().current_scene.call_deferred("add_child", ally)


func _setup_phase5():
	# Snow map — items to collect
	var center = Vector2(5000, 5000)
	uranium_pos = center + Vector2(randf_range(2000, 3500), randf_range(-2000, 2000))
	uranium_pos.x = clamp(uranium_pos.x, 500, 9500)
	uranium_pos.y = clamp(uranium_pos.y, 500, 9500)
	rocket_body_pos = center + Vector2(randf_range(-3500, -2000), randf_range(-2000, 2000))
	rocket_body_pos.x = clamp(rocket_body_pos.x, 500, 9500)
	rocket_body_pos.y = clamp(rocket_body_pos.y, 500, 9500)
	village_pos = center

	has_uranium = false
	has_rocket_body = false

	if GameManager.story_step == 11:
		_create_marker(uranium_pos, Color(0.2, 1, 0.2), "URANIUM")
	elif GameManager.story_step == 12:
		_create_marker(rocket_body_pos, Color(0.7, 0.7, 0.7), "ROCKET BODY")

	# Spawn surrounding monsters
	if GameManager.story_step == 10:
		call_deferred("_spawn_monster_ring")


func _spawn_monster_ring():
	var center = Vector2(5000, 5000)
	var swarmer_scene = preload("res://enemies/swarmer.tscn")
	for i in 40:
		var angle = i * TAU / 40
		var enemy = swarmer_scene.instantiate()
		enemy.global_position = center + Vector2(cos(angle) * 800, sin(angle) * 800)
		get_tree().current_scene.get_node("Enemies").call_deferred("add_child", enemy)
		WaveManager.enemies_alive += 1


func _process(_delta):
	if not GameManager.story_mode:
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	var step = GameManager.story_step
	match step:
		0:
			_update_arrow(player, scroll_pos)
			if player.global_position.distance_to(scroll_pos) < PICKUP_RADIUS:
				_advance(1, "You found the scroll! It's a treasure map!")
				_remove_marker("SCROLL")
				_create_marker(treasure_pos, Color(1, 0.85, 0), "TREASURE")
		1:
			_update_arrow(player, treasure_pos)
			if player.global_position.distance_to(treasure_pos) < PICKUP_RADIUS:
				_advance(2, "You found a pistol! Find a safe zone to open the shop!")
				_remove_marker("TREASURE")
				# Give pistol
				player.add_weapon("pistol")
		2:
			_find_nearest_safezone(player)
			_update_arrow(player, target_pos)
			quest_label.text = "Find a safe zone! (press E to open shop inside)"
			# Step 3 is triggered by shop.gd when shop is opened in safe zone
		3:
			arrow_label.visible = false
			# Start waves if not already running (shop was opened)
			if not WaveManager.wave_active and not WaveManager.buy_phase_active:
				_show_message("The monsters are coming! Defend yourself!")
				WaveManager.start_game()
			quest_label.text = "Kill 10 monsters! (%d/10)" % story_kills
			if story_kills >= 10:
				# Find a safe zone to burn as village
				var best_zone = null
				var best_dist = INF
				for zone in get_tree().get_nodes_in_group("safe_zones"):
					var dist = player.global_position.distance_to(zone.global_position)
					if dist > 500 and dist < best_dist:
						best_dist = dist
						best_zone = zone
				village_pos = best_zone.global_position if best_zone else Vector2(3000, 3000)
				_advance(4, "Well done! A village is under attack! Go save them!")
				_create_marker(village_pos, Color(1, 0.3, 0.1), "BURNING VILLAGE")
		4:
			_update_arrow(player, village_pos)
			if player.global_position.distance_to(village_pos) < 200:
				_advance(5, "The village is burning! Kill the monsters and save the villagers!")
				_remove_marker("BURNING VILLAGE")
				_spawn_village_battle()
		5:
			arrow_label.visible = false
			var enemies_left = get_tree().get_nodes_in_group("enemies").size()
			quest_label.text = "Save the village! Enemies left: %d" % enemies_left
			if enemies_left <= 0:
				_show_message("Village saved! Escaping to the forest...")
				GameManager.story_step = 6
				GameManager.map_type = GameManager.MapType.FOREST
				GameManager.save_story()
				get_tree().create_timer(3.0).timeout.connect(
					func(): get_tree().reload_current_scene()
				)
		6:
			_advance(7, "The forest! Tamed monsters fight alongside you. Kill 100 enemies!")
			story_kills = 0
			_ensure_waves_running()
		7:
			arrow_label.visible = false
			_ensure_waves_running()
			quest_label.text = "Forest battle! Kill 100 enemies! (%d/100)" % story_kills
			if story_kills >= 100:
				_show_message("Forest cleared! Moving to the battlefield...")
				GameManager.story_step = 8
				GameManager.map_type = GameManager.MapType.BATTLEFIELD
				GameManager.save_story()
				get_tree().create_timer(3.0).timeout.connect(
					func(): get_tree().reload_current_scene()
				)
		8:
			_advance(9, "The battlefield! Allies fight bosses! Kill 50 enemies!")
			story_kills = 0
			_ensure_waves_running()
		9:
			arrow_label.visible = false
			_ensure_waves_running()
			quest_label.text = "Battlefield! Kill 50 enemies! (%d/50)" % story_kills
			if story_kills >= 50:
				_show_message("Battle won! But the monsters surround you... Winter comes!")
				GameManager.story_step = 10
				GameManager.map_type = GameManager.MapType.SNOW
				GameManager.save_story()
				get_tree().create_timer(3.0).timeout.connect(
					func(): get_tree().reload_current_scene()
				)
		10:
			arrow_label.visible = false
			_ensure_waves_running()
			quest_label.text = "Surrounded! Break through the monster ring!"
			# Check if player escaped the ring (distance > 1200 from center)
			if player.global_position.distance_to(Vector2(5000, 5000)) > 1200:
				_advance(11, "You broke through! Find the Uranium!")
				_create_marker(uranium_pos, Color(0.2, 1, 0.2), "URANIUM")
		11:
			_update_arrow(player, uranium_pos)
			if player.global_position.distance_to(uranium_pos) < PICKUP_RADIUS:
				has_uranium = true
				_advance(12, "Uranium collected! Now find the Rocket Body!")
				_remove_marker("URANIUM")
				_create_marker(rocket_body_pos, Color(0.7, 0.7, 0.7), "ROCKET BODY")
		12:
			_update_arrow(player, rocket_body_pos)
			if player.global_position.distance_to(rocket_body_pos) < PICKUP_RADIUS:
				has_rocket_body = true
				_advance(13, "Rocket Body collected! Return to the village center!")
				_remove_marker("ROCKET BODY")
				_create_marker(Vector2(5000, 5000), Color(1, 0.85, 0), "VILLAGE")
		13:
			_update_arrow(player, Vector2(5000, 5000))
			if player.global_position.distance_to(Vector2(5000, 5000)) < 100:
				_advance(14, "Building the rocket...")
				_remove_marker("VILLAGE")
				_launch_rocket()
		14:
			pass  # Won game handled by _launch_rocket


func _advance(new_step: int, message: String):
	GameManager.story_step = new_step
	_update_quest_text()
	_show_message(message)
	GameManager.save_story()


func _ensure_waves_running():
	if not WaveManager.wave_active and not WaveManager.buy_phase_active:
		WaveManager.start_game()


func _on_kill():
	if GameManager.story_step in [3, 7, 9]:
		story_kills += 1


func _find_nearest_safezone(player):
	var min_dist = INF
	for zone in get_tree().get_nodes_in_group("safe_zones"):
		var dist = player.global_position.distance_to(zone.global_position)
		if dist < min_dist:
			min_dist = dist
			target_pos = zone.global_position


func _create_marker(pos: Vector2, color: Color, text: String):
	var marker = Node2D.new()
	marker.global_position = pos
	marker.name = "Marker_" + text.replace(" ", "_")
	var circle = Polygon2D.new()
	circle.color = Color(color.r, color.g, color.b, 0.4)
	var points = PackedVector2Array()
	for i in 16:
		var a = i * TAU / 16
		points.append(Vector2(cos(a) * 30, sin(a) * 30))
	circle.polygon = points
	circle.z_index = 5
	marker.add_child(circle)
	var lbl = Label.new()
	lbl.text = text
	lbl.position = Vector2(-30, -40)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", color)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.z_index = 10
	marker.add_child(lbl)
	get_tree().current_scene.call_deferred("add_child", marker)


func _remove_marker(text: String):
	var name = "Marker_" + text.replace(" ", "_")
	var marker = get_tree().current_scene.get_node_or_null(name)
	if marker:
		marker.queue_free()


func _update_quest_text():
	match GameManager.story_step:
		0: quest_label.text = "Find the ancient scroll near you!"
		1: quest_label.text = "Follow the map to the treasure!"
		2: quest_label.text = "Find a safe zone! (E to open shop)"
		3: quest_label.text = "Kill 10 monsters! (%d/10)" % story_kills
		4: quest_label.text = "Go to the burning village!"
		5: quest_label.text = "Save the village!"
		6: quest_label.text = "Arriving at the forest..."
		7: quest_label.text = "Forest battle! Kill 100! (%d/100)" % story_kills
		8: quest_label.text = "Arriving at the battlefield..."
		9: quest_label.text = "Battlefield! Kill 50! (%d/50)" % story_kills
		10: quest_label.text = "Break through the monster ring!"
		11: quest_label.text = "Find the Uranium!"
		12: quest_label.text = "Find the Rocket Body!"
		13: quest_label.text = "Return to village!"
		14: quest_label.text = "Victory!"


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


func _launch_rocket():
	# Rocket launch animation + win
	quest_label.text = "Launching the rocket!"
	arrow_label.visible = false

	# Kill all enemies on map
	get_tree().create_timer(2.0).timeout.connect(func():
		for enemy in get_tree().get_nodes_in_group("enemies"):
			enemy.call_deferred("queue_free")
		WaveManager.enemies_alive = 0
	)

	# Show win screen after delay
	get_tree().create_timer(4.0).timeout.connect(func():
		_show_win_screen()
	)


func _show_win_screen():
	GameManager.story_step = 14
	GameManager.delete_save()
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Full black background
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 1)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	# Credits container — starts below screen and scrolls up
	var credits = VBoxContainer.new()
	credits.alignment = BoxContainer.ALIGNMENT_CENTER
	credits.add_theme_constant_override("separation", 40)
	credits.mouse_filter = Control.MOUSE_FILTER_IGNORE
	credits.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	credits.modulate.a = 0.0
	add_child(credits)

	# Title
	_add_credit(credits, "THE END", 72, Color(1, 0.85, 0))

	# Spacer
	var sp1 = Control.new()
	sp1.custom_minimum_size = Vector2(0, 30)
	sp1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	credits.add_child(sp1)

	_add_credit(credits, "The rocket destroyed the monster horde.", 24, Color(0.8, 0.8, 0.8))
	_add_credit(credits, "The world is saved.", 24, Color(0.8, 0.8, 0.8))

	var sp2 = Control.new()
	sp2.custom_minimum_size = Vector2(0, 50)
	sp2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	credits.add_child(sp2)

	# Credits
	_add_credit(credits, "--- CREDITS ---", 28, Color(1, 0.85, 0))

	var sp3 = Control.new()
	sp3.custom_minimum_size = Vector2(0, 20)
	sp3.mouse_filter = Control.MOUSE_FILTER_IGNORE
	credits.add_child(sp3)

	_add_credit(credits, "Otletgazda", 20, Color(0.6, 0.6, 0.6))
	_add_credit(credits, "Janos Zsolt", 36, Color(1, 1, 1))

	var sp4 = Control.new()
	sp4.custom_minimum_size = Vector2(0, 20)
	sp4.mouse_filter = Control.MOUSE_FILTER_IGNORE
	credits.add_child(sp4)

	_add_credit(credits, "Fotervezo", 20, Color(0.6, 0.6, 0.6))
	_add_credit(credits, "Janos-Kevey Miklos", 36, Color(1, 1, 1))

	var sp5 = Control.new()
	sp5.custom_minimum_size = Vector2(0, 20)
	sp5.mouse_filter = Control.MOUSE_FILTER_IGNORE
	credits.add_child(sp5)

	_add_credit(credits, "Programozo", 20, Color(0.6, 0.6, 0.6))
	_add_credit(credits, "Claude", 36, Color(1, 1, 1))

	var sp6 = Control.new()
	sp6.custom_minimum_size = Vector2(0, 40)
	sp6.mouse_filter = Control.MOUSE_FILTER_IGNORE
	credits.add_child(sp6)

	_add_credit(credits, "Score: $%d | Total Kills: %d" % [GameManager.score, GameManager.kills], 22, Color(1, 0.85, 0))

	var sp7 = Control.new()
	sp7.custom_minimum_size = Vector2(0, 30)
	sp7.mouse_filter = Control.MOUSE_FILTER_IGNORE
	credits.add_child(sp7)

	_add_credit(credits, "Koszonjuk hogy jatszottal!", 28, Color(1, 0.85, 0))

	# Fade in credits
	var tween = credits.create_tween()
	tween.tween_property(credits, "modulate:a", 1.0, 2.0)

	# Main menu button after credits
	get_tree().create_timer(8.0).timeout.connect(func():
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
		credits.add_child(btn)
	)


func _add_credit(parent: Control, text: String, size: int, color: Color):
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)


func _show_message(text: String):
	var msg = Label.new()
	msg.text = text
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.position = Vector2(get_viewport().get_visible_rect().size.x / 2 - 250, 120)
	msg.add_theme_font_size_override("font_size", 20)
	msg.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
	msg.custom_minimum_size = Vector2(500, 0)
	msg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	msg.z_index = 100
	add_child(msg)
	var tween = msg.create_tween()
	tween.tween_property(msg, "modulate:a", 0.0, 5.0)
	tween.chain().tween_callback(msg.queue_free)
